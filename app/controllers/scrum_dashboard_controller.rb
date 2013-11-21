
class ScrumDashboardController < ApplicationController
   unloadable
   DFL_PARAMS = {
      :sprint_number => 1,
      :sprint_cf_name => "Sprint",
      :responsible_cf => "responsible"
   }

   

   def index
      sprint_cf = CustomField.find_by_name(DFL_PARAMS[:sprint_cf_name])
      @sprint_names = sprint_cf.possible_values
      users_cf = CustomField.find_by_name(DFL_PARAMS[:responsible_cf])
      @users = []
      if users_cf 
        @users = users_cf.possible_values.collect {|uname| [uname, uname]}
      end
      if params[:sprint_names]
        # Use selected projects id
        @selected_sprint = params[:sprint_names].collect {|s| s.to_i}
      else
        # If no projects selected then select all
        @selected_sprint = DFL_PARAMS[:sprint_number]
      end
     
     
  end
  
  def burndown_data()
     sprint_cf = CustomField.find_by_name(DFL_PARAMS[:sprint_cf_name])
     sprint_names = sprint_cf.possible_values
     selected_sprint = params[:selected_sprint]     
     selected_user = ""
     burndown_data = nil
     query = ""
     unless params[:selected_user].nil? || params[:selected_user] == "null"
        # We get the burndown data by Sprint and User
        burndown_data = BurndownData.all(
            :select => "query_date,sprint,responsible,SUM(remaining_hours) as total_remaining_hours",
            :conditions => ['sprint = ? AND responsible = ?',selected_sprint, params[:selected_user]],
            :group => "query_date,sprint,responsible", :order => "query_date")

        # We get the sprint total estimated hours by Sprint and responsible
        query = "SELECT SUM(estimated_hours) from tasks " +
            " WHERE sprint =  \"#{selected_sprint}\" AND responsible = \"#{params[:selected_user]}\" "
     else
        # We get the burndown data by Sprint
       burndown_data = BurndownData.all(
           :select => "query_date,sprint,responsible,SUM(remaining_hours) as total_remaining_hours",
           :conditions => ['sprint = ?',selected_sprint],
           :group => "query_date", :order => "query_date")

       # We get the sprint total estimated hours by Sprint
       query = "SELECT SUM(estimated_hours) from tasks " +
           " WHERE sprint =  \"#{selected_sprint}\""
     end

     # FIXME replace this query by a RoR model for user_stories
     total_hours_res = ActiveRecord::Base.connection.execute(query)
     total_hours = 0
     total_hours_res.each() {|row|
       total_hours = row[0].to_i unless row[0].nil?
     }

     # We get the data from the selected sprint
     current_sprint = Sprint.find_by_name(selected_sprint)

     
     burndown = Burndown.new(current_sprint, burndown_data, total_hours)
     
     burndown_chart = burndown.chart()
     respond_to do |format|
        format.json { render :json => burndown_chart }
     end    
 
  end

  private
  
   
  def transform_projects_to_strset(selected_projects, field_name)
    if selected_projects == nil || selected_projects.size == 0
      return ""
    end
    
    if selected_projects.size == 1
      return "and #{field_name} = #{selected_projects[0]}"
    end

    set_string = "(#{selected_projects[0]}"
    for i in 1...selected_projects.size
      set_string += ", #{selected_projects[i]}"
    end
    set_string += ")"

    return "and #{field_name} in #{set_string}"
  end

  def is_empty(field)
    if !field || field.blank?
      return true
    end
    return false
  end

  
  def algun_metodo_privado

  end
end
