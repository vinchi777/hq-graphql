# frozen_string_literal: true

require "rails_helper"

describe ::HQ::GraphQL::Schema do
  let(:query) do
    Class.new(::HQ::GraphQL::Object) do
      graphql_name "Query"

      field :field, ::GraphQL::Types::Int, null: false
    end
  end

  before(:each) do
    stub_const("Query", query)
  end

  after(:all) do
    ::FileUtils.rm_rf(Rails.root.join("files")) if ::File.directory?(Rails.root.join("files"))
  end

  context "when the dump directory and filename are given" do
    let(:class_name) { "TestSchema" }

    let(:schema) do
      Object.const_set(class_name, Class.new(::HQ::GraphQL::Schema) do
        dump_directory Rails.root.join("files")
        dump_filename "temp_schema.graphql"
        query(Query)
      end)
    end

    it "should write the schema successfully to the filepath" do
      schema.dump
      expect(schema.dump_directory).to eq(Rails.root.join("files"))
      expect(schema.dump_filename).to eq("temp_schema.graphql")
      file_contents = ::File.read(::File.join(schema.dump_directory, schema.dump_filename))
      expect(file_contents).to eq(schema.to_definition)
    end
  end

  context "when the dump directory is not given" do
    let(:class_name) { "NoDirSchema" }

    let(:schema) do
      Object.const_set(class_name, Class.new(::HQ::GraphQL::Schema) do
        dump_filename "temp_schema.graphql"
        query(Query)
      end)
    end

    after(:all) do
      file_directory = ::File.dirname(::HQ::GraphQL::Schema.method(:dump_directory).source_location.first)
      filepath = "#{file_directory}/temp_schema.graphql"
      ::File.delete(filepath) if ::File.exist?(filepath)
    end

    it "should use the current directory" do
      schema.dump
      expected_filepath = schema.method(:dump_directory).source_location.first
      expect(schema.dump_directory).to eq(File.dirname(expected_filepath))

      file_contents = ::File.read(::File.join(schema.dump_directory, schema.dump_filename))
      expect(file_contents).to eq(schema.to_definition)
    end
  end

  context "when the dump filename is not given" do
    let(:class_name) { "NoFilenameSchema" }

    let(:schema) do
      Object.const_set(class_name, Class.new(::HQ::GraphQL::Schema) do
        dump_directory Rails.root.join("files")
        query(Query)
      end)
    end

    it "should use the class name as the filename" do
      schema.dump
      expect(schema.dump_filename).to eq("#{class_name.underscore}.graphql")
      file_contents = ::File.read(::File.join(schema.dump_directory, schema.dump_filename))
      expect(file_contents).to eq(schema.to_definition)
    end
  end
end
