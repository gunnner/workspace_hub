require 'rails_helper'

RSpec.describe Project, type: :model do
  let(:organization) { create(:organization) }

  describe 'tenant scoping' do
    it 'validates presence of organization' do
      project = build(:project, organization: nil)
      expect(project).to be_invalid
      expect(project.errors[:organization]).to include('must exist')
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      ActsAsTenant.with_tenant(organization) do
        project = build(:project, organization: organization, name: nil)
        expect(project).to be_invalid
        expect(project.errors[:name]).to include("can't be blank")
      end
    end
  end

  describe 'associations' do
    it 'belongs to organization' do
      ActsAsTenant.with_tenant(organization) do
        project = create(:project, organization: organization)
        expect(project.organization).to eq(organization)
        expect(project.class.reflect_on_association(:organization).macro).to eq(:belongs_to)
      end
    end

    it 'has many tasks' do
      ActsAsTenant.with_tenant(organization) do
        project = create(:project, organization: organization)
        expect(project.class.reflect_on_association(:tasks).macro).to eq(:has_many)
        expect(project.class.reflect_on_association(:tasks).options[:dependent]).to eq(:destroy)
      end
    end

    it 'validates organization is required' do
      project = build(:project, organization: nil)
      expect(project).to be_invalid
      expect(project.errors[:organization]).to be_present
    end
  end

  describe 'tenant isolation' do
    it 'only returns projects for current tenant' do
      org1 = create(:organization, subdomain: 'org1')
      org2 = create(:organization, subdomain: 'org2')

      project1 = ActsAsTenant.with_tenant(org1) do
        create(:project, organization: org1, name: 'Project 1')
      end

      project2 = ActsAsTenant.with_tenant(org2) do
        create(:project, organization: org2, name: 'Project 2')
      end

      ActsAsTenant.with_tenant(org1) do
        expect(Project.all).to include(project1)
        expect(Project.all).not_to include(project2)
      end

      ActsAsTenant.with_tenant(org2) do
        expect(Project.all).to include(project2)
        expect(Project.all).not_to include(project1)
      end
    end
  end
end
