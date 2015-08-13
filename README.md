# Tempest

Tempest is a ruby library and DSL for generating AWS CloudFormation templates.

## Features

* Libraries allow creating a collection of reusable components, which can be
  reused throughout many templates.
* Components imported from a library can have selected parameters overwritten.
  For example, you might change the default value for a parameter from what is
  in the library.
* Component inheritance also allows duplicating and/or renaming components
* Automatically trims out parameters and mappings that aren't required. Your
  entire library of parameters and mappings won't be included in every
  template.
* Validates references. Will fail to compile if a resource references a
  parameter that doesn't exist, or is invalid.
* Helper functions and factories can be used to simplify common patterns.

## TODO

* CLI tool to generate templates to a file or S3 object

## Example

The ruby version:

    Tempest::Library.add(:example) do
      # We define a parameter here. We will use this definition as a template
      # for other parameters, but since this parameter is not referenced
      # directly it won't be included in the output.
      parameter(:instance_type).create(:string,
        :description => 'Type of EC2 instance',
        :constraint_description => 'Must be a valid EC2 instance type',
        :allowed_values => [
          "m3.medium",
          "m3.large",
          "m3.xlarge",
          "m3.2xlarge"
        ]
      )

      factory(:server).create(:name => :string, :ami => :string) do
        resource(name).create('AWS::EC2::Instance',
          # parameter.with_prefix creates a new parameter such as
          # web_server_instance_type, copying the options. You may also
          # selectively overwrite specific options.
          :instance_type => parameter(:instance_type).with_prefix(name)
        )
      end
    end

    Tempest::Template.new do
      use library(:example)

      description 'Example template'

      servers = {
        :web_server  => 'ami-123456',
        :db_server   => 'ami-234567',
        :mail_server => 'ami-345678'
      }

      servers.each do |name, ami|
        factory(:server).construct(name, ami)
      end
    end

Will compile to:

    {
      "Description": "Example template",
      "Parameters": {
        "WebServerInstanceType": {
          "Type": "String",
          "Description": "Type of EC2 instance",
          "ConstraintDescription": "Must be a valid EC2 instance type",
          "AllowedValues": [
            "m3.medium",
            "m3.large",
            "m3.xlarge",
            "m3.2xlarge"
          ]
        },
        "DbServerInstanceType": {
          "Type": "String",
          "Description": "Type of EC2 instance",
          "ConstraintDescription": "Must be a valid EC2 instance type",
          "AllowedValues": [
            "m3.medium",
            "m3.large",
            "m3.xlarge",
            "m3.2xlarge"
          ]
        },
        "MailServerInstanceType": {
          "Type": "String",
          "Description": "Type of EC2 instance",
          "ConstraintDescription": "Must be a valid EC2 instance type",
          "AllowedValues": [
            "m3.medium",
            "m3.large",
            "m3.xlarge",
            "m3.2xlarge"
          ]
        }
      },
      "Resources": {
        "WebServer": {
          "Type": "AWS::EC2::Instance",
          "Properties": {
            "InstanceType": {
              "Ref": "WebServerInstanceType"
            }
          }
        },
        "DbServer": {
          "Type": "AWS::EC2::Instance",
          "Properties": {
            "InstanceType": {
              "Ref": "DbServerInstanceType"
            }
          }
        },
        "MailServer": {
          "Type": "AWS::EC2::Instance",
          "Properties": {
            "InstanceType": {
              "Ref": "MailServerInstanceType"
            }
          }
        }
      }
    }
