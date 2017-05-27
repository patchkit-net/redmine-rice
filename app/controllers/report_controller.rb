class ReportController < ApplicationController
  unloadable

  before_action :find_project, :authorize

  def index
    @issues = @project.issues.includes(:custom_values).joins(:status).where('issue_statuses.is_closed = ?', false)
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
        reach_weight = Setting.plugin_rice_reports['reach_weight'].to_f
        impact_weight = Setting.plugin_rice_reports['impact_weight'].to_f
        confidence_weight = Setting.plugin_rice_reports['confidence_weight'].to_f

        score = ((reach_weight * reach) * (impact_weight * impact) * (confidence_weight * confidence)) / (issue.estimated_hours / 160)
        score = score.round(2)
      end

      [issue, score]
    end

    @issues_to_score.reject! { |is| is[1].nil? }
    @issues_to_score.sort! { |a, b| a[1] <=> b[1] }
    @issues_to_score.reverse!

    @issues_without_score = @issues.reject do |issue|
      @issues_to_score.any? { |its| its[0] == issue }
    end
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
    end
end
