class ReportController < ApplicationController
  unloadable

  before_action :find_project, :authorize

  def index
    @issues = collect_issues_recursively(@project)
    @hide_resolved = !params[:hide_resolved].blank?
    if @hide_resolved
      @issues.reject! { |is| is.status.name == 'Resolved' }
    end

    @issues_to_score = @issues.map do |issue|
      score = nil
      reach = nil, confidence = nil, impact = nil
      issue.custom_values.each do |custom_value|
        case custom_value.custom_field.name
        when 'Reach'
          reach = custom_value.value.to_f
        when 'Impact'
          impact = custom_value.value.to_f
        when 'Confidence'
          confidence = custom_value.value.to_f
        end
      end

      if !reach.nil? && !impact.nil? && !confidence.nil? && !issue.estimated_hours.nil? && issue.estimated_hours != 0
        score = (reach * impact * confidence) / (issue.estimated_hours / 160)
        score = score.round(2)
      end

      [issue, score]
    end

    @issues_to_score.reject! { |is| is[1].nil? }
    @issues_to_score.sort! { |a, b| [a[0].priority, a[1]] <=> [b[0].priority, b[1]] }
    @issues_to_score.reverse!

    @issues_without_score = @issues.reject do |issue|
      @issues_to_score.any? { |its| its[0] == issue }
    end
  end

  def collect_issues_recursively(project)
    issues = project.issues.joins(:status).where('issue_statuses.is_closed = ?', false).all
    project.children.each do |child_project|
      issues += collect_issues_recursively(child_project)
    end
    issues
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
    end
end
