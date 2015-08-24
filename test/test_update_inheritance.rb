require 'minitest/autorun'
require 'tempest'

class TestInheritanceUpdates < Minitest::Test
  def test_parameter_inheritance
    Tempest::Library.new(:test_parameter_update_inheritance_inner) do
      parameter(:bar).create(:string, :description => "Test parameter")
    end
    Tempest::Library.new(:test_parameter_update_inheritance_outer) do
      use library(:test_parameter_update_inheritance_inner)

      parameter(:bar).update(:default => "Foo")
    end

    tmpl = Tempest::Template.new do
      use library(:test_parameter_update_inheritance_outer)
      resource(:foo).create('AWS::EC2::Instance', :bar => parameter(:bar))
    end

    expected_output = {
      "Resources" => {
        "Foo" => {
          "Type" => 'AWS::EC2::Instance',
          "Properties" => {
            "Bar" => { 'Ref' => 'Bar' }
          }
        }
      },
      "Parameters" => {
        "Bar" => {
          "Type" => "String",
          "Description" => "Test parameter",
          "Default" => "Foo"
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end

  def test_mapping_inheritance
    Tempest::Library.new(:test_mapping_update_inheritance_inner) do
      mapping(:bar).create(
        'Bar' => {
          'Baz' => 'Quux'
        }
      )
    end
    Tempest::Library.new(:test_mapping_update_inheritance_outer) do
      use library(:test_mapping_update_inheritance_inner)

      mapping(:bar).update(
        'Baz' => {
          'Quux' => 'Quuz'
        }
      )
    end
    tmpl = Tempest::Template.new do
      use library(:test_mapping_update_inheritance_outer)
      resource(:foo).create('AWS::EC2::Instance', :bar => mapping(:bar).find('Bar', 'Baz'))
    end

    expected_output = {
      "Resources" => {
        "Foo" => {
          "Type" => 'AWS::EC2::Instance',
          "Properties" => {
            "Bar" => { "Fn::FindInMap" => ['Bar', 'Bar', 'Baz'] }
          }
        }
      },
      "Mappings" => {
        "Bar" => {
          "Bar" => {
            "Baz" => "Quux"
          },
          "Baz" => {
            "Quux" => "Quuz"
          }
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end
end
