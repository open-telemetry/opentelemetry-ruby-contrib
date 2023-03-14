::GraphQL::Schema.instance_eval do
  def trace_class(new_class = nil)
    if new_class
      @trace_class = new_class
    elsif !defined?(@trace_class)
      parent_trace_class = if superclass.respond_to?(:trace_class)
        superclass.trace_class
      else
        GraphQL::Tracing::Trace
      end
      @trace_class = Class.new(parent_trace_class)
    end
    @trace_class
  end
end
