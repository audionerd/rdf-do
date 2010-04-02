require 'data_objects'

module RDF
  module DataObjects
    class Repository

      include RDF::Enumerable, RDF::Queryable, RDF::Mutable, RDF::Durable

      def initialize(options = {})
        case options
          when String
            @db     = ::DataObjects::Connection.new(options)
          when Hash
            @db     = ::DataObjects::Connection.new(options[:db])
            adapter = options[:adapter]
          when nil
            @db    = ::DataObjects::Connection.new('sqlite3://:memory:')
        end
        adapter = @db.instance_variable_get("@uri").scheme
        begin
          require 'rdf/do/adapters/' + adapter.to_s
        rescue LoadError => e
          warn "Unable to find adapter '#{adapter}'."
          raise e
        end
        @adapter = RDF::DataObjects::Adapters::const_get(adapter.to_s.capitalize).new(@db)
        @adapter.migrate?
      end

      def dispose
        close
        @db.dispose
      end

      def close
        @db.close
        @adapter = nil
      end

      def count
        @adapter.count
      end

      def empty?
        count == 0
      end

      def insert(*statements)
        @adapter.insert *statements
      end

      def insert_statement(statement)
        insert *[statement]
      end

      def delete(*statements)
        @adapter.delete *statements
      end

      def delete_statement(statement)
        delete *[statement]
      end

      def each(&block)
        if block_given?
          @adapter.each &block
        else
          enum_statements(@adapter, :each, @adapter)
        end
      end

      def enum_statements
        ::Enumerable::Enumerator.new(@adapter, :each)
      end

    end
  end
end

