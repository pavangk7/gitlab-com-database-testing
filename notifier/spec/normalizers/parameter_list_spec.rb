# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Normalizers::ParameterList do

  it 'normalizes sql with a list of literals' do
    sql = <<~SQL
    INSERT INTO namespaces (tmp_project_id, name, path, parent_id, visibility_level, shared_runners_enabled, type, created_at, updated_at) SELECT projects.id, projects.name, projects.path, projects.namespace_id, projects.visibility_level, shared_runners_enabled, $1, now(), now() FROM "projects" WHERE "projects"."id" IN ($3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) ON CONFLICT DO NOTHING
    SQL

    query_data = PgQuery.parse(PgQuery.normalize(sql))
    # query_data = PgQuery.parse(sql)
    expect(described_class.normalize(query_data).deparse).to eq(sql)
  end
end