module ProjectsTreeView
  module ProjectsHelperPatch
    extend ActiveSupport::Concern

    module ClassMethods
    end

    def render_project_progress(project)
      s = ''
      cond = project.project_condition(false)

      open_issues = Issue.visible.includes(:project, :status).where(["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false]).references(:project, :status).count

      if project.issues.count > 0
		if open_issues == project.issues.count
			issues_closed_percent = 100
		else
			issues_closed_percent = (1 - open_issues.to_f/project.issues.count) * 100
		end
        s << "<div>Tarefas: " +
          link_to("#{open_issues} abertas", :controller => 'issues', :action => 'index', :project_id => project, :set_filter => 1) +
          "<small> / #{project.issues.count} total</small></div>" +
          progress_bar(issues_closed_percent, :width => '30em', :legend => '%0.0f%' % issues_closed_percent)
      end
      project_versions = project_open(project)

      unless project_versions.empty?        
      end
      s.html_safe
    end

    def favorite_project_modules_links(project)
      links = []
      menu_items_for(:project_menu, project) do |node|
         links << link_to(extract_node_details(node, project)[0], extract_node_details(node, project)[1]) unless node.name == :overview
      end
      links.join(", ").html_safe
    end

    def project_open(project)
      #trackers = project.trackers.order(:position)
      #retrieve_selected_tracker_ids(trackers, trackers.select {|t| t.is_in_roadmap?})
      with_subprojects =  Setting.display_subprojects_issues?
      project_ids = with_subprojects ? project.self_and_descendants.collect(&:id) : [project.id]

      versions = project.shared_versions || []
      versions += project.rolled_up_versions.visible if with_subprojects
      versions = versions.uniq.sort
      completed_versions = versions.select {|version| version.closed? || version.completed? }
      versions -= completed_versions

      issues_by_version = {}
      versions.reject! {|version| !project_ids.include?(version.project_id) && issues_by_version[version].blank?}
      versions
    end
  end
end
