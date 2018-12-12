//compactscript.js


const margin = { top: 90.59, right: 3960-3815.83, bottom: 2880-2475.82, left: 467.53 };
const width = 3960 - margin.left - margin.right;
const height = 2880 - margin.top - margin.bottom;

const containerheight = document.getElementById('compactContainer').scrollHeight

const bisectDem = d3.bisector(d => d.demneed).left;
const bisectRep = d3.bisector(d => d.repneed).left;
const formatValue = d3.format(',.2f');

const x = d3.scaleLinear()
  .range([0, width]);

const y = d3.scaleLinear()
  .range([height, 0]);

const demline = d3.line()
  .x(d => x(d.demneed))
  .y(d => y(d.demseats));

const repline = d3.line()
  .x(d => x(d.repneed))
  .y(d => y(d.repseats));


const svg = d3.select('#compact').append('svg')
  .attr('viewBox', [-margin.left,-margin.top,3960,2880]);

d3.csv("/compactlines.csv", type, (error, data) => {
  if (error) throw error;

  const ylims = [Math.min(d3.min(data, d => d.demseats),d3.min(data, d => d.repseats)),
        Math.max(d3.max(data, d => d.demseats),d3.max(data, d => d.repseats))]
  const xlims = [Math.min(d3.min(data, d => d.demneed),d3.min(data, d => d.repneed)),
        Math.max(d3.max(data, d => d.demneed),d3.max(data, d => d.repneed))]
  x.domain(xlims)
  y.domain(ylims)

    
  const focusline3 = svg.append('g')
    .attr('class', 'focus3')
    .style('display', 'none');

  focusline3.append('line')
    .classed('y', true)
    .styles({
      fill: 'none',
      'stroke': '#888',
      'stroke-width': '2',
      'stroke-dasharray': '5 5'
    });

  /*svg.append('path')
    .datum(data)
    .attr('class', 'line')
    .attr("d", repline)
    .attr("stroke", "rgb(220 34 34)")
    .styles({
      fill: 'none',
      'stroke-width': '17',
      'shape-rendering': 'crispEdges',
      'opacity': '1'
    });

  svg.append("path")
    .datum(data)
    .attr("class", "line")
    .attr("d", demline)
    .attr("stroke", "rgb(22 107 170)").styles({
      fill: 'none',
      'stroke-width': '17',
      'shape-rendering': 'crispEdges',
      'opacity': '1'
    });*/

  svg.append('svg').attr('viewBox', [margin.left,margin.top,3960,2880]).html('<line x1="2699.85" y1="1108.83" x2="2699.85" y2="1072.95" stroke-linecap="round" style="fill:none;stroke:#000000;stroke-width:12.96"/>' +
  '<line x1="2699.85" y1="889.05" x2="2699.85" y2="853.16" stroke-linecap="round" style="fill:none;stroke:#000000;stroke-width:12.96"/>' +
  '<line x1="2699.85" y1="937.06" x2="2730.05" y2="929.39" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2730.05" y1="929.39" x2="2760.12" y2="921.60" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2760.12" y1="921.60" x2="2790.32" y2="913.92" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2790.32" y1="913.92" x2="2820.51" y2="906.25" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2820.51" y1="906.25" x2="2850.58" y2="898.58" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2850.58" y1="898.58" x2="2880.78" y2="890.90" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2880.78" y1="890.90" x2="2910.85" y2="883.23" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2910.85" y1="883.23" x2="2941.04" y2="875.43" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2941.04" y1="875.43" x2="2971.11" y2="867.76" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="2971.11" y1="867.76" x2="3001.31" y2="860.09" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="3001.31" y1="860.09" x2="3031.38" y2="852.42" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="3031.38" y1="852.42" x2="3061.57" y2="844.74" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="3061.57" y1="844.74" x2="3091.65" y2="836.95" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>' +
  '<line x1="3091.65" y1="836.95" x2="3121.84" y2="829.27" stroke-linecap="round" style="stroke:#000000;stroke-width:4.32"/>');

  const focus3 = svg.append('g')
    .attr('class', 'focus3')
    .style('display', 'none');

  function newsize(x) {
    return Math.max(1.2*x, 1.2*x*500/containerheight);
  }

  const tooltipheight = 400
  const rectwidth = newsize(318)
  const rectheight = newsize(250)
  const rect_y = -newsize(80)
  const rect_x = newsize(36)
  const rectround = newsize(30)
  const rectcolor = '#555'
  const triangle = [6,0,rect_x,-rect_x/2,rect_x,rect_x/2]
  const fliptriangle = [-6,0,-rect_x,-rect_x/2,-rect_x,(rect_x)/2]
  const text_x_pad = rect_x + newsize(26)
  const text_y_pad = rect_y + newsize(53)
  const small_gap = newsize(54)
  const big_gap = newsize(59)
  const xvaloffset = 1.2*66


  focus3.append('rect')
    .attr('class', 'notflipped')
    .attr('width', rectwidth)
    .attr('height', rectheight)
    .attr('y', rect_y)
    .attr('x', rect_x)
    .attr('rx', rectround)
    .style('fill', rectcolor);

  focus3.append('polygon')
    .attr('class', 'notflipped')
    .attr('points', triangle)
    .style('stroke', rectcolor)
    .style('fill', rectcolor);

  focus3.append('text')
    .attr('class','demlab notflipped')
    .attr('x', text_x_pad)
    .attr('y', text_y_pad);

  focus3.append('text')
    .attr('class','demval notflipped')
    .attr('x', text_x_pad)
    .attr('y', text_y_pad+small_gap);

  focus3.append('text')
    .attr('class','replab notflipped')
    .attr('x', text_x_pad)
    .attr('y', text_y_pad+small_gap+big_gap);

  focus3.append('text')
    .attr('class','repval notflipped')
    .attr('x', text_x_pad)
    .attr('y', text_y_pad+small_gap+big_gap+small_gap);

    focus3.append('text')
    .attr('class','xval')
    .attr('x', 0)
    .attr('y', height-tooltipheight+xvaloffset)
    .attr('alignment-baseline', 'baseline');

  focus3.append('rect')
    .attr('class', 'flipped')
    .attr('width', rectwidth)
    .attr('height', rectheight)
    .attr('y', rect_y)
    .attr('x', -rectwidth-rect_x)
    .attr('rx', rectround)
    .style('fill', rectcolor);

  focus3.append('polygon')
    .attr('points', fliptriangle)
    .attr('class', 'flipped')
    .style('stroke', rectcolor)
    .style('fill', rectcolor);

  focus3.append('text')
    .attr('class','demlab flipped')
    .attr('x', -rectwidth-2*rect_x+text_x_pad)
    .attr('y', text_y_pad);

  focus3.append('text')
    .attr('class','demval flipped')
    .attr('x', -rectwidth-2*rect_x+text_x_pad)
    .attr('y', text_y_pad+small_gap);

  focus3.append('text')
    .attr('class','replab flipped')
    .attr('x', -rectwidth-2*rect_x+text_x_pad)
    .attr('y', text_y_pad+small_gap+big_gap);

  focus3.append('text')
    .attr('class','repval flipped')
    .attr('x', -rectwidth-2*rect_x+text_x_pad)
    .attr('y', text_y_pad+small_gap+big_gap+small_gap);

  const focuses = d3.selectAll('.focus3')

  svg.append('rect')
    .attr('class', 'overlay')
    .attr('width', width)
    .attr('height', height+xvaloffset)
    .on('mouseover', mouseover)
    .on('mouseout', () => focuses.style('display', 'none'))
    .on('mousemove', mousemove)
    .styles({
      fill: 'none',
      'pointer-events': 'all'
    });

  /*d3.selectAll('.focus3 line')
    .styles({
      fill: 'none',
      'stroke': '#888',
      'stroke-width': '10',
      'stroke-dasharray': '5 5'
    });*/
  function mouseover() {
    focuses.style('display', null);
    const x0 = x.invert(d3.mouse(this)[0]);
    const i = bisectDem(data, x0, 1);
    const j = bisectRep(data, x0, 1);
    const rep = data[j];
    const dem = data[i];
    focuses.attr('transform', `translate(${(x0-xlims[0])*width/(xlims[1]-xlims[0])}, ${tooltipheight})`);

    focusline3.select('line.y')
      .attr('x1', 0)
      .attr('x2', 0)
      .attr('y1', -tooltipheight)
      .attr('y2', height - tooltipheight);

    const xvalheight = 38*1.7;
    const labheight = 27.5*1.7;
    const yvalheight = 32*1.7;

    focus3.selectAll('.flipped').style('visibility', 'hidden')
    focus3.selectAll('.xval').text(Math.round((x0-50)*2*10)/10).style('text-anchor', 'middle').style('font', newsize(xvalheight) +'px sans-serif')
      .attr('x', Math.max(Math.min(0,(97*(xlims[1]-xlims[0])/100-(x0-xlims[0]))*width/(xlims[1]-xlims[0])),(4*(xlims[1]-xlims[0])/100-(x0-xlims[0]))*width/(xlims[1]-xlims[0])));

    focus3.selectAll('.demlab').text("Democrats:").style('text-anchor', 'left').style('font', newsize(labheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.demval').text(dem.demseats).style('text-anchor', 'left').style('font', newsize(yvalheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.replab').text("Republicans:").style('text-anchor', 'left').style('font', newsize(labheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.repval').text(rep.repseats).style('text-anchor', 'left').style('font', newsize(yvalheight)+'px sans-serif').style('fill','#FFFFFF');
    if((x0-xlims[0])*width/(xlims[1]-xlims[0])+rect_x+rectwidth<width){
      focus3.selectAll('.flipped').style('visibility', 'hidden')
      focus3.selectAll('.notflipped').style('visibility', 'visible')
    }
    if((x0-xlims[0])*width/(xlims[1]-xlims[0])+rect_x+rectwidth>=width){
      focus3.selectAll('.notflipped').style('visibility', 'hidden')
      focus3.selectAll('.flipped').style('visibility', 'visible')
    }
  }

  function mousemove() {
    const x0 = x.invert(d3.mouse(this)[0]);
    const i = bisectDem(data, x0, 1);
    const j = bisectRep(data, x0, 1);
    const rep = data[j];
    const dem = data[i];
    focuses.attr('transform', `translate(${(x0-xlims[0])*width/(xlims[1]-xlims[0])}, ${tooltipheight})`);

    focusline3.select('line.y')
      .attr('x1', 0)
      .attr('x2', 0)
      .attr('y1', -tooltipheight)
      .attr('y2', height - tooltipheight);

    const xvalheight = 38*1.7;
    const labheight = 27.5*1.7;
    const yvalheight = 32*1.7;

    focus3.selectAll('.flipped').style('visibility', 'hidden')
    focus3.selectAll('.xval').text(Math.round((x0-50)*2*10)/10).style('text-anchor', 'middle').style('font', newsize(xvalheight) +'px sans-serif')
      .attr('x', Math.max(Math.min(0,(97*(xlims[1]-xlims[0])/100-(x0-xlims[0]))*width/(xlims[1]-xlims[0])),(4*(xlims[1]-xlims[0])/100-(x0-xlims[0]))*width/(xlims[1]-xlims[0])));

    focus3.selectAll('.demlab').text("Democrats:").style('text-anchor', 'left').style('font', newsize(labheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.demval').text(dem.demseats).style('text-anchor', 'left').style('font', newsize(yvalheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.replab').text("Republicans:").style('text-anchor', 'left').style('font', newsize(labheight)+'px sans-serif').style('fill','#FFFFFF');
    focus3.selectAll('.repval').text(rep.repseats).style('text-anchor', 'left').style('font', newsize(yvalheight)+'px sans-serif').style('fill','#FFFFFF');
    if((x0-xlims[0])*width/(xlims[1]-xlims[0])+rect_x+rectwidth<width){
      focus3.selectAll('.flipped').style('visibility', 'hidden')
      focus3.selectAll('.notflipped').style('visibility', 'visible')
    }
    if((x0-xlims[0])*width/(xlims[1]-xlims[0])+rect_x+rectwidth>=width){
      focus3.selectAll('.notflipped').style('visibility', 'hidden')
      focus3.selectAll('.flipped').style('visibility', 'visible')
    }

  }
});

function type(d) {
  d.demneed = +d.demneed;
  d.demseats = +d.demseats;
  d.repneed= +d.repneed;
  d.repseats = +d.repseats;
  return d;
}

