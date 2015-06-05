require 'elasticsearch/persistence/model'

class ElasticsearchDocument
  module ElasticsearchHelpers
    def facetable field, type
      attribute field, type, mapping: {
        fields: {
          field: { type: 'string' },
          raw: { type: 'string', index: 'not_analyzed' }
        }
      } 
    end

    def sortable field, type
      attribute field, type, mapping: {
        fields: {
          field: { type: 'string' },
          raw: { type: 'string', index: 'not_analyzed' }
        }
      }
    end
  end

  attr_reader :model

  def self.configure! index, &block
    klass = Class.new

    # Index name is inferred from the class name; since this is
    # an anonymous class, define a .model_name class method that
    # returns an ActiveModel::Name to satisfy Elasticsearch::Persistence::Model
    klass.define_singleton_method :model_name do
      ActiveModel::Name.new(self, nil, index)
    end

    klass.class_eval do
      include Elasticsearch::Persistence::Model
      extend ElasticsearchHelpers
    end

    klass.class_eval(&block)

    @model = klass
  end

  def to_partial_path
    'catalog/document'
  end

  def key? k
    attributes.include? k.to_sym
  end

  def _source
    self
  end

  def method_missing(m, *args, &b)
    if @model.respond_to?(m)
      @model.send(m, *args, &b)
    else
      super
    end
  end
end
