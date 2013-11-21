class BacklogController < ApplicationController
  unloadable
  DFL_PARAMS = {
    :min => 20,
    :avg => 30,
    :max => 40,
    :num_sprints => 1
  }

  def index

    @projects = Project.all.collect {|p| [p.name, p.id]}
    if params[:projects]
      # Use selected projects id
      @selected_projects = params[:projects].collect {|p| p.to_i}
    else
      # If no projects selected then select all
      @selected_projects = @projects.collect {|p| p[1] }
    end
    
    # We get the versions
    @versions = Version.all.collect {|v| [v.name, v.id]}
    # We'll use this map in the view to display the name of each version
    @verIdToName = Hash[ @versions.map{ |v| [ v[1].to_s, v[0] ] } ]
    
    if params[:versions]
       @selected_versions = params[:versions].collect {|v| v.to_i}
       #if no versions selected, then select none
    end

    projects_set = transform_projects_to_strset(@selected_projects, "project_id")
    versions_set = transform_projects_to_strset(@selected_versions, "fixed_version_id");


        query = "select project_name,q1.id,subject,size,market,urgency,tech,priority,@running_total := @running_total + size AS cumulative_sum_of_size from (
select project_name,concat('<a href=\"/redmine/issues/',u.id,'\" >',u.id,'</a>') as id,
subject,size,market,urgency,tech,( (u.market -50)+(u.urgency-50)+(u.tech-50)+1000 )*((40-least(u.size  ,40))/40 ) as priority from user_stories u
join issue_statuses s on u.status_id=s.id
where u.market is not null
#{projects_set} #{versions_set}
and u.urgency is not null
and u.tech is not null
and s.name='In Planning' 
order by priority desc) as q1
JOIN (SELECT @running_total := 0) r"
    
    @result = ActiveRecord::Base.connection.execute(query)

       
    # Get the values and chech if is nil, negative or zero
    # Then assign the default value and show an error flash message 
    # Assign to session variables
    min = load_value(params, 'min')
    avg = load_value(params, 'avg')
    max = load_value(params, 'max')
    num_sprints = load_value(params, 'num_sprints')

    session[:num_sprints] = num_sprints

    # check that the values are increaring min <= avg <= max
    if min <= avg
      if avg <= max
        # The happy scenario
        session[:min] = min
        session[:avg] = avg
        session[:max] = max
      else
        # avg > max
        session[:min] = min
        session[:avg] = avg
        session[:max] = avg
        flash.now[:error] = "Avg can't be greater than Max. Assigning Avg the value of Max"
      end
    else
      # min > avg
      if avg <= max
        session[:min] = avg
        session[:avg] = avg
        session[:max] = max
        flash.now[:error] = "Min can't be greater than Avg. Assigning Min the value of Avg"
      else
        # min > avg & avg > max
        session[:min] = min
        session[:avg] = min
        session[:max] = min
        flash.now[:error] = "The general rule for velocity is min <= avg <= max. Assigning Avg and Max with Min value"
      end
    end
  end
  
  private 

  def load_value(params, symbol)
    value  = params[symbol.to_sym]
    if is_empty(value)
      value = DFL_PARAMS[symbol.to_sym]
      return value
    end
    value = value.to_i
    if value <= 0
      flash.now[:error] = "'#{symbol}' has to  be an integer greater than 0"
      value = DFL_PARAMS[symbol.to_sym]
      return value
    end
    return value
  end

  # TODO change the name and identifiers associated to this method
  # to more generic ones 
  
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
end
