require 'minitest/autorun'
require 'tempest'

class TestTemplate < Minitest::Test
  def test_resource_output
    tmpl = Tempest::Template.new do
      resource(:foo).create('AWS::EC2::Instance', :bar => "baz")
    end

    expected_output = {
      "Resources" => {
        "Foo" => {
          "Type" => 'AWS::EC2::Instance',
          "Properties" => {
            "Bar" => "baz"
          }
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end

  def test_parameter_output
    tmpl = Tempest::Template.new do
      parameter(:bar).create(:string, :description => "Test parameter")

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
          "Description" => "Test parameter"
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end

  def test_mapping_output
    tmpl = Tempest::Template.new do
      mapping(:bar).create(
        'Bar' => {
          'Baz' => 'Quux'
        }
      )

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
          }
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end

  def test_mapping_output
    tmpl = Tempest::Template.new do
      resource(:foo).create('AWS::EC2::Instance', :bar => 'Baz')
      output(:bar).create(resource(:foo))
    end

    expected_output = {
      'Resources' => {
        'Foo' => {
          'Type' => 'AWS::EC2::Instance',
          'Properties' => {
            'Bar' => 'Baz',
          }
        }
      },
      'Outputs' => {
        'Bar' => {
          'Value' => { 'Ref' => 'Foo' }
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end

  def test_conition_output
    tmpl = Tempest::Template.new do
      resource(:foo).create(
        'AWS::EC2::Instance',
        :condition => condition(:bar),
        :bar       => condition(:bar).if('Quux', 'Quuz')
      )
      condition(:bar).equals('Bar', 'Baz')
    end

    expected_output = {
      'Resources' => {
        'Foo' => {
          'Type' => 'AWS::EC2::Instance',
          'Properties' => {
            'Condition' => 'Bar',
            'Bar' => {
              'Fn::If' => [
                'Bar',
                'Quux',
                'Quuz'
              ]
            },
          }
        }
      },
      'Conditions' => {
        'Bar' => {
          'Fn::Equals' => [
            'Bar',
            'Baz'
          ]
        }
      }
    }

    assert_equal(tmpl.to_h, expected_output)
  end
end
