const width = document.getElementById('doubleContainer').scrollWidth
const horizontaldivheight = .48*width*2880/3960+4
const verticaldivheight = (.88889*width*2880/3960+4)*2
if(width>1000){
	d3.select('#doubleContainer').style('height', horizontaldivheight+'px')
	document.getElementById('doubleContainer').innerHTML=
	'<div id="proportionalContainer" style="width:48%;float:left;margin-left:1%;margin-right:1%;position:relative;">' +
	'<img src="proportionalclean.svg" style="display: block;max-width: 100%;height: auto;">' +
	'<svg viewBox="0 0 3960 2880" style="position: absolute;top: 0;left: 0;" id="proportional">' +
	'</svg>' +
	'</div>' +
	'<div id="competitiveContainer" style="width:48%;float:left;margin-left:1%;margin-right:1%;position:relative;">' +
	'<img src="competitiveclean.svg" style="display: block;max-width: 100%;height: auto;">' +
	'<svg viewBox="0 0 3960 2880" style="position: absolute;top: 0;left: 0;" id="competitive">' +
	'</svg>'+
	'</div>'
} else {
	d3.select('#doubleContainer').style('height', verticaldivheight+'px')
	document.getElementById('doubleContainer').innerHTML=
	'<div id="proportionalContainer" style="width:88.88889%;float:left;margin-left:5.55556%;margin-right:5.55556%;position:relative;">' +
	'<img src="proportionalclean.svg" style="display: block;max-width: 100%;height: auto;">' +
	'<svg viewBox="0 0 3960 2880" style="position: absolute;top: 0;left: 0;" id="proportional">' +
	'</svg>' +
	'</div>' +
	'<div id="competitiveContainer" style="width:88.88889%;float:left;margin-left:5.55556%;margin-right:5.55556%;position:relative;">' +
	'<img src="competitiveclean.svg" style="display: block;max-width: 100%;height: auto;">' +
	'<svg viewBox="0 0 3960 2880" style="position: absolute;top: 0;left: 0;" id="competitive">' +
	'</svg>'+
	'</div>'
}