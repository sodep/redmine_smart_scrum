// Dealing with namespace
jQuery.noConflict();


var SMS_PLUGIN;
if (!SMS_PLUGIN){
	SMS_PLUGIN = {};
}

/** Global objects */
var _burndownManager;
var _chartManager;

jQuery(document).ready(function($){
	_chartManager = SMS_PLUGIN.ChartManager($);
	
	// Getting burndown data via AJAX
	_burndownManager = SMS_PLUGIN.BurnDownManager($);
	
        //_burndownManager.getDataAndDrawChart();
	
       	$("#select_sprint_button").click(function() {
           var sprint = loadSelectedSprint($);
           _burndownManager.getDataAndDrawChart(sprint);
        });
        
        $("#select_user_button").click(function() {
           var sprint = _burndownManager.getSprint();
           if (!sprint) {
              sprint = loadSelectedSprint($);
           }
           var userId = $("#users_names_").val();
           var userLogin = $("#users_names_ option[value='"+userId+"']").text();
           var user = {login: userLogin, id: userId};
           _burndownManager.getDataAndDrawChart(sprint, user);
        });		

});

function loadSelectedSprint($) {
    var sprintId = $("#sprint_names_").val();
    var sprintName = $("#sprint_names_ option[value='"+
                  sprintId+"']").text();
    return {name : sprintName, id: sprintId};
      
}

SMS_PLUGIN.BurnDownManager = function($) {
   var that = {};
   var _sprint;
   var _user;
   that.getDataAndDrawChart = function(sprint, user) {
     
      _sprint = sprint;
      
      var userLogin = null;
      if (user) {
         //_user = user;  
         userLogin = user.login;
      }   

      $.ajax({
         type: "POST",
         url: "scrum_dashboard/burndown_data",
         data: {"selected_sprint" : _sprint.id,
                "selected_user" : userLogin, 
         // Necessary due to an issue with Rails and
         // AJAX requests. Not sure what Rails version      
                "authenticity_token": AUTH_TOKEN},
         dataType: "json",
         beforeSend: function() {
            if ($("#ajax-indicator")) {
               $("#ajax-indicator").show();
            }
         },
         success: function(jsonData){
              if (!user) {
                  _chartManager.drawLineChart(jsonData[0], 
                     sprint.name, "holder1");
               } else { 
                  var tittle = sprint.name + ". User " + user.login; 
                  _chartManager.drawLineChart(jsonData[0],
                    tittle, "holder2");
               }
         },
         complete: function() {
             if ($("#ajax-indicator")) {
               $("#ajax-indicator").hide();
            }
         },
         error: function(xhr, textStatus, errorThrown){
            alert("Error: " + textStatus + 
            "\nRequest status: " + xhr.status +
            "\nText: " + xhr.statusText );
         } 			
      });
   };
   that.getSprint = function() {
      return _sprint;
   }; 
   return that;
};

SMS_PLUGIN.ChartManager = function($) {
   var that = {};
   var _rapha;
   var WIDTH = 500;   //460
   var WIDTH_PIX = 50;
   var HEIGHT = 300;	
   var TOP = 80;  //40
   var LEFT = 60;//60

   that.setRaphael = function(r){
      _rapha = r;
   };
   
   that.getRaphael = function() {
      return _rapha;
   };
   
   that.drawLineChart = function(burnData, tittle, holderId) {

      $('#general_msg_holder').empty();
      $("#" + holderId).empty();


      if (burnData.error_msg && burnData.error_msg != null) {
        showChartErrorMsg('general_msg_holder', burnData.error_msg);
        return;
      }

      var chartTittle = "Burndown for " + tittle;
      var rapha = Raphael(holderId), txtattr = { font: "12px sans-serif" };
      
      rapha.text(parseInt( (WIDTH+LEFT)/2 , 10), 30, chartTittle).attr(txtattr);

      // Parameters for the linechart method
      var xAxisValues = [];
      var yAxisValues = [];
      var sprint_data =  burnData.data[0].sprint_data;


      if (sprint_data.length === 0) {
         showChartErrorMsg(holderId, "No data to display for " + tittle);
         return;
      }

      if (sprint_data.length == 1) {
          // FIXME Temporal solution. g.raphael cannot draw the chart if we only pass
          // one point x,y to it. For now, we avoid that issue with this
          showChartErrorMsg(holderId, "There is not enough data to display the chart");
          return;
      }
      
      var xDatesValues = [];
      for(var i = 0; i < sprint_data.length; i++) {
         if (sprint_data[i].query_date) {
            xAxisValues.push(i);
            var timeMilSecs = Number(sprint_data[i].query_date) * 1000;
            var d = new Date(timeMilSecs);
            xDatesValues.push(d.getTime());
         }
         var hours = sprint_data[i].total_remaining_hours;
         yAxisValues.push(parseInt(hours));
      }

      // Array of x coordinates equal in length to ycoords
      var xCoordsArr = [];
      var ideal_data = burnData.data[0].ideal_data;
      var idealStartDate = new Date(ideal_data[0][0] * 1000);
      var idealEndDate = new Date(ideal_data[1][0] * 1000);
      var lastIndex = xAxisValues.length - 1;
      var lastSprintDate = new Date(xDatesValues[lastIndex]);
      var offsetInDays = calcDifferenceInDays(lastSprintDate, idealEndDate);

      // We add the days left to complete the sprint, if the
      // sprint data does not cover the whole sprint
      if (offsetInDays > 0) {
          for (var days = 1 ; days <= offsetInDays; days++) {
              xAxisValues.push(lastIndex + days);
              var d = new Date(lastSprintDate);
              d.setDate(d.getDate() + days);
              xDatesValues.push(d.getTime());
          }
      }

      //var idealXArr = [0, xAxisValues.length - 1 + offsetInDays];
      var idealXArr = [0, xAxisValues.length - 1];
     
     
      if (xAxisValues.length > 0) {
         xCoordsArr =  [xAxisValues, idealXArr];
      }
      
      var yCoordsArr = [];
       
      var total_hours1 = parseInt(ideal_data[0][1]);
      var total_hours2 = parseInt(ideal_data[1][1]);
      var idealYArr = [total_hours1, total_hours2];
         
      if (yAxisValues.length > 0) {
         yCoordsArr = [yAxisValues, idealYArr];
      }



      var options =  { nostroke: false, 
                   axis: "0 0 1 1", 
                   symbol: "circle", 
                   smooth: true ,
                   "axisxstep" : xAxisValues.length - 1 };
      
      var lines = rapha.linechart(
         TOP,  // X start in pixels 
         LEFT,  // Y start in pixels
         (xAxisValues.length - 1) * WIDTH_PIX, // Width of chart in pixels
         HEIGHT, // Height of chart in pixels
         xCoordsArr, 
         yCoordsArr, 
         options
      );
      lines.hoverColumn(function(){
        var r = rapha;
        this.tags = r.set();
        // console.log("hover: " + this.y.length);
        for (var i = 0; i < this.y.length; i++) {
          var dateValue = xDatesValues[this.axis];
          var d = new Date(dateValue);
          var dateStr = getDateStr(d);
          var label = "h: " + this.values[i] + ". d: " + dateStr;
          // We should add this because in the offset days we don't have
          // any hours values (y axis)
          if (!this.y[i])  {
            return;
          }
          var tempTag = r.tag(this.x, this.y[i], label , 160, 10);
          var fillArr = [
             {fill: "#fff"},
             {fill: this.symbols[i].attr("fill")}
          ];
          tempTag.insertBefore(this).attr(fillArr);
          this.tags.push(tempTag);   
        }
      },function(){
         this.tags && this.tags.remove();
      }); 
      
      // Iterate through the array of dom elems,
      // the current dom elem will be i
      // axis_labels = burnData.axis_labels[0];
      // if (!axis_labels ||  axis_labels.length === 0) {
      //   return;
      // }

       // We try to set the custom labels
       var axisItems = lines.axis[0].text.items;

       for(var i = 0, n = axisItems.length;  i < n; i++){
         // var time = parseInt(xText[i].attr("text"));
         var time = xDatesValues[i];
         var d = new Date(time);
         var dateStr = getDateStr(d);
         // Set the text of the current elem with the result
         axisItems[i].attr({'text': dateStr });
      };
      
     lines.symbols.attr({ r : 3 });
 
   };
   var getDateStr = function(d) {
      var dayStr = d.getDate() < 10 ? '0' + d.getDate() : d.getDate();
      var month = d.getMonth() + 1;
      var monthStr = month < 10 ? '0' + month : month;
      var yearStr = d.getYear();
      var dateStr = monthStr + "/" + dayStr;
      return dateStr;    
   };

   var showChartErrorMsg = function(holderId, msg) {
       var p = $("<p></p>").addClass("nodata").text(msg);
       $("#" + holderId).html(p);
   };

   var  calcDifferenceInDays = function(dDate1, dDate2) { // input given as Date objects
        var iWeeks, iDateDiff, iAdjust = 0;
        if (dDate2 < dDate1) return -1; // error code if dates transposed
        var iWeekday1 = dDate1.getDay(); // day of week
        var iWeekday2 = dDate2.getDay();

        iWeekday1 = (iWeekday1 == 0) ? 7 : iWeekday1; // change Sunday from 0 to 7
        iWeekday2 = (iWeekday2 == 0) ? 7 : iWeekday2;


        //if ((iWeekday1 > 5) && (iWeekday2 > 5)) iAdjust = 1; // adjustment if both days on weekend
       /*
       iWeekday1 = (iWeekday1 > 5) ? 5 : iWeekday1; // only count weekdays
        iWeekday2 = (iWeekday2 > 5) ? 5 : iWeekday2;
          */

        // calculate differnece in weeks (1000mS * 60sec * 60min * 24hrs * 7 days = 604800000)
        iWeeks = Math.floor((dDate2.getTime() - dDate1.getTime()) / 604800000);

        if (iWeekday1 <= iWeekday2) {
            iDateDiff = (iWeeks  * 7) + (iWeekday2 - iWeekday1);
        } else {
            iDateDiff = ((iWeeks + 1) * 7) - (iWeekday1 - iWeekday2);
        }

        iDateDiff -= iAdjust // take into account both days on weekend

        return iDateDiff; // add 1 because dates are inclusive
    };

   return that;
};
