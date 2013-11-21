class Burndown

  attr_accessor :dates, :version, :start_date

  delegate :to_s, :to => :chart
  
 
  # FIXME refactor this method's parameters definition
  def initialize(current_sprint, burndown_data, total_sprint_hours)
    
    unless current_sprint.nil?
      # We calculate the date range for the x axis of the chart   	
      ideal_start = current_sprint.starts_on.to_i
      ideal_end = current_sprint.ends_on.to_i

      @ideal_data = [
          [ideal_start, total_sprint_hours], [ ideal_end, 0]
      ]

    else
      @error_msg = "No start/end date for selected Sprint. Please check the sprints table"
      self.dates = []
    end

    @sprint_data = burndown_data.collect {|bd|
      bd.query_date = bd.query_date.to_i
      bd
    }

  end

  def chart()
    [
      :data => [:ideal_data => @ideal_data ,
      :sprint_data => @sprint_data],
      :error_msg => @error_msg
    ]
  end

  # From a date string parses a date object with
  # the specified format
  def to_js_date(dateStr)
     format = "%Y-%m-%d %H:%M:%S"     
     DateTime.strptime(dateStr, format)
  end

end
