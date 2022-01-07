# frozen_string_literal: true
module Normalizers
  class ParameterList
    def self.normalize(query)
      query.send(:treewalker!, query.tree) do |parent_node, parent_field, node, location|
        next unless location.last == :list

        if is_literal_param_list?(node)
          replacement = PgQuery::Node.new
          replacement['a_const'] = PgQuery::A_Const.new
          replacement['a_const']['val'] = PgQuery::Node.new
          replacement['a_const']['val']['string'] = PgQuery::String.new
          replacement['a_const']['val']['string']['str'] = 'replaced literal parameter list'
          loop do
            # Ridiculous way to empty and refill this array-like object, but it works.
            break if node['items'].shift.nil?
          end
          # items are now empty, so we can push our replacement
          node['items'].push(replacement)
        end

        node
      end

      query
    end

    def self.is_literal_param_list?(node)
      node['items'].length >= 5 && node['items'].map { |i| i['param_ref'] }.all? { |v| v.is_a?(PgQuery::ParamRef) }
    end
  end
end
