# Tempest

Tempest is a ruby library and DSL for generating AWS CloudFormation templates.

## Features

* Define parameters, mappings, etc by inheriting from other definitions.
  Anything not referenced by a resource won't be included in the output.
* Validates references. Will fail to compile if a resource references a
  parameter that doesn't exist, won't allow you to reference mappings directly,
  etc.

## TODO

* Define/include libraries of definitions that can be referenced from multiple
  templates.
* CLI tool to generate templates to a file.
* Schemas? Ensure resources have the correct parameters (or just rely on AWS
  validation?)

## Example

The ruby version:

    Tempest::Template.new do
      description 'Example template'

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

      servers = {
        :web_server  => 'ami-123456',
        :db_server   => 'ami-234567',
        :mail_server => 'ami-345678'
      }

      servers.each do |name, ami|
        resource(name).create('AWS::EC2::Instance',
          # parameter.with_prefix creates a new parameter such as
          # web_server_instance_type, copying the options. You may also
          # selectively overwrite specific options.
          :instance_type => parameter(:instance_type).with_prefix(name)
        )
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
