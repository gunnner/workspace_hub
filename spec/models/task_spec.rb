require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:organization) { create(:organization) }
  let(:project) do
    ActsAsTenant.with_tenant(organization) do
      create(:project, organization: organization)
    end
  end

  describe 'tenant scoping' do
    it 'inherits organization from project' do
      ActsAsTenant.with_tenant(organization) do
        task = create(:task, project: project)
        expect(task.organization).to eq(organization)
      end
    end
  end

  describe 'validations' do
    it 'validates presence of title' do
      ActsAsTenant.with_tenant(organization) do
        task = build(:task, project: project, title: nil)
        expect(task).to be_invalid
        expect(task.errors[:title]).to include("can't be blank")
      end
    end

    it 'validates presence of project' do
      task = build(:task, project: nil)
      expect(task).to be_invalid
      expect(task.errors[:project]).to include('must exist')
    end
  end

  describe 'associations' do
    it 'belongs to project' do
      ActsAsTenant.with_tenant(organization) do
        task = create(:task, project: project)
        expect(task.project).to eq(project)
        expect(task.class.reflect_on_association(:project).macro).to eq(:belongs_to)
      end
    end

    it 'belongs to organization' do
      ActsAsTenant.with_tenant(organization) do
        task = create(:task, project: project)
        expect(task.organization).to eq(organization)
        expect(task.class.reflect_on_association(:organization).macro).to eq(:belongs_to)
      end
    end

    it 'validates organization is required' do
      task = Task.new(title: 'Tets', organization: nil, project: nil)
      expect(task).to be_invalid
      expect(task.errors[:organization]).to include('must exist')
    end

    it 'automatically sets organization from projects' do
      ActsAsTenant.with_tenant(organization) do
        task = build(:task, project: project, organization: nil)
        task.valid? # trigger validation in set_organization_from_project hook
        expect(task.organization).to eq(project.organization)
      end
    end
  end

  describe 'tenant isolation' do
    it 'only returns tasks for current tenant' do
      org1 = create(:organization, subdomain: 'org1')
      org2 = create(:organization, subdomain: 'org2')

      project1 = ActsAsTenant.with_tenant(org1) do
        create(:project, organization: org1)
      end

      project2 = ActsAsTenant.with_tenant(org2) do
        create(:project, organization: org2)
      end

      task1 = ActsAsTenant.with_tenant(org1) do
        create(:task, project: project1, title: 'Task 1')
      end

      task2 = ActsAsTenant.with_tenant(org2) do
        create(:task, project: project2, title: 'Task 2')
      end

      ActsAsTenant.with_tenant(org1) do
        expect(Task.all).to include(task1)
        expect(Task.all).not_to include(task2)
      end

      ActsAsTenant.with_tenant(org2) do
        expect(Task.all).to include(task2)
        expect(Task.all).not_to include(task1)
      end
    end
  end
end
