//multigraph.do

local shift = $shift
local maps = "algorithmiccompact Compact Competitive Proportional Dem GOP"
local marginlimits = 20

local axismin = 217
local axismax = 218 //these get set below
preserve
foreach altmap of local maps { //this is entirely a dry run of the code to find the extrema to size the axes
//it's important everything is plotted on the same y-axis, and there's no easy way to pick the best one inside the real loop
	if "`altmap'" == "algorithmiccompact" local altmapname = "Compact Districts"
	if "`altmap'" == "Compact" local altmapname = "Compact, Follow County Borders"
	if "`altmap'" == "Dem" local altmapname = "Democratic Gerrymander"
	if "`altmap'" == "GOP" local altmapname = "Republican Gerrymander"
	if "`altmap'" == "Competitive" local altmapname = "Competitive"
	if "`altmap'" == "Proportional" local altmapname = "Proportional"

	sum voteshare
	destring v2, gen(district) ignore("AL")
	replace district = 0 if district == .
	sort v1 district
	gen index = _n
	bys v1: egen uniqueid = min(index)
	replace uniqueid = uniqueid*60+district
	tempfile results
	save `results'
	import delim data/districts538, clear
	replace maptype = "algorithmiccompact" if maptype == "algorithmic-compact"
	keep if maptype=="`altmap'"|maptype=="current"
	gen statedistrict = statefp+district*60
	sort statefp
	gen sortorder = _n if maptype=="`altmap'"
	keep pvi state district statedistrict sortorder maptype pvi
	reshape wide pvi sortorder, i(statedistrict) j(maptype) string
	sort sortorder`altmap'
	gen index=_n
	rename district district538
	bys state: egen uniqueid = min(index)
	replace uniqueid = uniqueid*60+district538
	drop sortorder*
	merge 1:1 uniqueid using `results', nogen

	reg demshare c.pvicurrent##c.pvicurrent if state != "PA"
	gen fakeshare = _b[pvicurrent]*pvi`altmap'+_b[c.pvicurrent#c.pvicurrent]*pvi`altmap'*pvi`altmap'+_b[_cons]

	gen fakerepneed = fakeshare
	gen fakedemneed = 100-fakerepneed
	sort fakerepneed
	gen fakerepseats = _n
	sort fakedemneed
	gen fakedemseats = _n
	tempfile all fake
	save `all'
	keep fake*
	gen sortorder = _n
	save `fake'
	use `all'


	gen repneed = demshare //Repub would win the seat with >demshare
	gen demneed = 100-repneed
	sort demneed

	gen sortorder = _n
	drop fake*
	merge 1:1 sortorder using `fake', nogen

	local lowerlim = 50-`marginlimits'/2
	local upperlim = 50+`marginlimits'/2
	replace fakerepneed = . if !inrange(fakerepneed,`lowerlim',`upperlim')
	replace fakerepseats = . if fakerepneed == .
	replace fakedemneed = . if !inrange(fakedemneed,`lowerlim',`upperlim')
	replace fakedemseats = . if fakedemneed == .
	qui sum fakedemseats
	local demmin = r(min)
	local demmax = r(max)
	qui sum fakerepseats
	local repmin = r(min)
	local repmax = r(max)
	di "`demmin',`repmin',`axismin'"
	local axismin = min(`demmin',`repmin',`axismin')
	local axismax = max(`demmax',`repmax',`axismax')
	restore, preserve
}


local counter = 1
foreach altmap of local maps {
	if "`altmap'" == "algorithmiccompact" local altmapname = "Compact Districts"
	if "`altmap'" == "Compact" local altmapname = "Compact, Follow County Borders"
	if "`altmap'" == "Dem" local altmapname = "Democratic Gerrymander"
	if "`altmap'" == "GOP" local altmapname = "Republican Gerrymander"
	if "`altmap'" == "Competitive" local altmapname = "Competitive"
	if "`altmap'" == "Proportional" local altmapname = "Proportional"

	sum voteshare
	destring v2, gen(district) ignore("AL")
	replace district = 0 if district == .
	sort v1 district
	gen index = _n
	bys v1: egen uniqueid = min(index)
	replace uniqueid = uniqueid*60+district
	tempfile results
	save `results'
	import delim data/districts538, clear
	replace maptype = "algorithmiccompact" if maptype == "algorithmic-compact"
	keep if maptype=="`altmap'"|maptype=="current"
	gen statedistrict = statefp+district*60
	sort statefp
	gen sortorder = _n if maptype=="`altmap'"
	keep pvi state district statedistrict sortorder maptype pvi
	reshape wide pvi sortorder, i(statedistrict) j(maptype) string
	sort sortorder`altmap'
	gen index=_n
	rename district district538
	bys state: egen uniqueid = min(index)
	replace uniqueid = uniqueid*60+district538
	drop sortorder*
	merge 1:1 uniqueid using `results', nogen

	reg demshare c.pvicurrent##c.pvicurrent if state != "PA"
	gen fakeshare = _b[pvicurrent]*pvi`altmap'+_b[c.pvicurrent#c.pvicurrent]*pvi`altmap'*pvi`altmap'+_b[_cons]

	gen fakerepneed = fakeshare
	gen fakedemneed = 100-fakerepneed
	sort fakerepneed
	gen fakerepseats = _n
	sort fakedemneed
	gen fakedemseats = _n
	

	tempfile all fake
	save `all'
	keep fake*
	gen sortorder = _n
	save `fake'
	use `all'


	gen repneed = demshare //Repub would win the seat with >demshare
	gen demneed = 100-repneed
	sort repneed
	gen repseats = _n
	sort demneed
	gen demseats = _n

	gen sortorder = _n
	drop fake*
	merge 1:1 sortorder using `fake', nogen
	
	local demgot = 50+`shift'
	gen gotten = demneed<=`demgot'
	qui sum gotten
	replace gotten = .
	replace gotten = r(sum) in 1
	local gotten = r(sum)
	gen wouldvegotten = repneed<=`demgot'
	qui sum wouldvegotten
	replace wouldvegotten = .
	replace wouldvegotten = r(sum) in 1
	
	gen fakegotten = fakedemneed<=`demgot'
	qui sum fakegotten
	replace fakegotten = .
	replace fakegotten = r(sum) in 1
	local fakegotten = r(sum)
	gen fakewouldvegotten = fakerepneed<=`demgot'
	qui sum fakewouldvegotten
	replace fakewouldvegotten = .
	replace fakewouldvegotten = r(sum) in 1
	
	expand 2, gen(add)
	replace demseats=demseats-add
	replace repseats=repseats-(1-add)
	replace fakedemseats=fakedemseats-add
	replace fakerepseats=fakerepseats-(1-add)
	sort demneed demseats
	
	
	set obs `=_N+2'
	replace fakerepseats = 0 in `=_N-1'  //this sets the theoretical values of (0,0) and (100,435); they get dropped if they aren't needed
	replace fakedemseats = 435 in `=_N-1'
	replace fakerepneed = 0 in `=_N-1'
	replace fakedemneed = 100 in `=_N-1'
	replace fakerepseats = 435 in `=_N'
	replace fakedemseats = 0 in `=_N'
	replace fakerepneed = 100 in `=_N'
	replace fakedemneed = 0 in `=_N'
	sort fakedemneed fakedemseats
	gen popshare2018 = `demgot' if gotten != .
	gen fakeand_tothe_left = popshare2018+4

	
	gen proportional = repseats*100/435 if fakerepseats!=0&fakedemseats!=0
	gen proportionallabel = "Proportional" if repseats ==64
	replace repseats = 0 if fakerepseats == 0
	replace demseats = 435 if fakerepseats == 0
	replace repneed = 0 if fakerepseats == 0
	replace demneed = 100 if fakerepseats == 0
	replace repseats = 435 if fakedemseats == 0
	replace demseats = 0 if fakedemseats == 0
	replace repneed = 100 if fakedemseats == 0
	replace demneed = 0 if fakedemseats == 0
	sort demneed demseats
	gen down = gotten - 7
	gen and_tothe_right = popshare2018+1.3
	gen left_alittle = popshare2018 - 0.5
	gen left_alittlemore = popshare2018
	gen majority = 218
	
	local demmarkerloc=3
	local replabgap=1
	local demlabsize = "mlabsize(small)"
	if "`altmap'" == "Dem" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*1.5 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.075 if inrange(fakedemseats,161,175)&add==0
		local demmarkerloc=1
		
		gen repx = popshare2018-0.25
		gen repy = wouldvegotten-3.75
	}
	if "`altmap'" == "Proportional" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.875 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.225 if inrange(fakedemseats,161,175)&add==0
		
		local replabgap=.6
		gen repx = popshare2018
		gen repy = wouldvegotten
	}
	if "`altmap'" == "Compact" {
		gen fakeline = `fakegotten'+(fakedemseats-161) if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.23 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018-0.25
		gen repy = wouldvegotten+2
	}
	if "`altmap'" == "GOP"{
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.45 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.13 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018
		gen repy = wouldvegotten
		local replabgap=.6
		
		replace and_tothe_right = popshare2018+0.81
		replace down = gotten - 8.4
		local demlabsize = "mlabsize(vsmall)"
	}
	if "`altmap'" == "Competitive"{
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.5 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.13 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018+1.39
		gen repy = wouldvegotten+8
	}
	if "`altmap'" == "algorithmiccompact" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*1.1 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.225 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018+0.65
		gen repy = wouldvegotten+10.5
	}
	
	qui sum fakedemneed if fakedemneed>41.6
	gen label538 = `"non-partisan districts"' if fakedemneed == r(min)
	qui sum demneed if demneed>47.3
	gen reglab = `"actual districts"' if demneed == r(min)
	qui sum demneed if demneed>32
	gen demlab = `"Democrats"' if demneed == r(min)
	qui sum repneed if repneed>28
	gen replab = `"Republicans"' if repneed == r(min)
	gen goodmargin = repneed-demneed
	local wouldvegotten = wouldvegotten
	sum goodmargin if repseats==`gotten'
	local repmarg = round(r(mean),0.01)
	if abs(`repmarg')<1 local repmarg =  "0`repmarg'"
	local demmarg = round(2*`shift',0.01)
	di "`demmarg'"
	
	local lowerlim = 50-`marginlimits'/2
	local upperlim = 50+`marginlimits'/2
	replace proportional = . if !inrange(proportional,`lowerlim',`upperlim')
	gen proportionalseats = repseats if proportional != .
	replace repneed = . if !inrange(repneed,`lowerlim',`upperlim')
	replace repseats = . if repneed == .
	replace demneed = . if !inrange(demneed,`lowerlim',`upperlim')
	replace demseats = . if demneed == .
	gen emptyfinder=_n
	qui sum emptyfinder if demseats==.&repseats==.&proportional==.
	local emptyrow = r(min)
	local emptyrow2 = r(max)
	if `emptyrow'!=. {
		qui sum demseats //this keeps the graph going to the bounds; it's the equivalent of (100,435) for the graph max
		replace demseats = r(min) in `emptyrow'
		replace demneed = `lowerlim' in `emptyrow'
		replace demseats = r(max) in `emptyrow2'
		replace demneed = `upperlim' in `emptyrow2'
		qui sum repseats
		replace repseats = r(max) in `emptyrow'
		replace repneed = `upperlim' in `emptyrow'
		replace repseats = r(min) in `emptyrow2'
		replace repneed = `lowerlim' in `emptyrow2'
	}
	
	gen majoritylabel = "Majority (218)" if repseats == r(min)

		
	replace fakerepneed = . if !inrange(fakerepneed,`lowerlim',`upperlim')
	replace fakerepseats = . if fakerepneed == .
	replace fakedemneed = . if !inrange(fakedemneed,`lowerlim',`upperlim')
	replace fakedemseats = . if fakedemneed == .
	gen fakeemptyfinder=_n
	qui sum fakeemptyfinder if fakedemseats==.&fakerepseats==.&proportional==.
	local fakeemptyrow = r(min)
	local fakeemptyrow2 = r(max)
	if `fakeemptyrow'!=. {
	qui sum fakedemseats
	replace fakedemseats = r(min) in `fakeemptyrow'
	replace fakedemneed = `lowerlim' in `fakeemptyrow'
	replace fakedemseats = r(max) in `fakeemptyrow2'
	replace fakedemneed = `upperlim' in `fakeemptyrow2'
	qui sum fakerepseats
	replace fakerepseats = r(max) in `fakeemptyrow'
	replace fakerepneed = `upperlim' in `fakeemptyrow'
	replace fakerepseats = r(min) in `fakeemptyrow2'
	replace fakerepneed = `lowerlim' in `fakeemptyrow2'
	}
	local yaxislab = ""
	if mod(`counter',3)==1 local yaxislab = `"ylab(245 "Seats", add custom notick labsize(medsmall) labgap(*7))"'
	//if mod(`counter',3)!=1 local yaxislab= `"`yaxislab' labcolor(white)"' (this would space them evenly)
	//local yaxislab = `"`yaxislab')"'
	local xaxistitle = `"xtitle("Popular Vote Margin", height(4))"'
	if `counter'<4 local xaxistitle= `"xtitle("", height(0))"'
	local ticknum = 2*int(`marginlimits'/10)
	local symbol = "pipe"
	if c(version)<15 local symbol = "Oh"
	
	sum fakeline
	local liny = r(max)
	sum fakelinex
	local linx = r(max)
	gen linelab = `fakegotten'
	
	
			
	twoway scatter fakegotten popshare2018, m(none) mcol(gs8) msize(small) || ///
		connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.5) mlabcol(gs5) || ///
		connected majority repneed, lcolor(sand) lwidth(medthin) m(none)|| ///
		line repseats repneed, lcolor("220 34 34*.36") || ///
		connected demseats demneed, lcolor("22 107 170*.36") m(none)|| ///
		line fakerepseats fakerepneed, lcolor("220 34 34") || ///
		connected fakedemseats fakedemneed, lcolor("22 107 170") m(none)|| ///
		line fakeline fakelinex, lcolor(black) lwidth(vthin) || ///
		scatteri `liny' `linx' (`demmarkerloc') "`fakegotten'", m(none) mlabsize(small) mlabcol("22 107 170") mlabgap(*0.2) || ///
		scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) `demlabsize' mlabcol("22 107 170*.6") || ///
		scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter repy repx, m(none) mlab(wouldvegotten) mlabpos(10) mlabsize(small) mlabcol("220 34 34*.6") mlabgap(*`replabgap') ///
		ylab(100 200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%  ") ///
		xtick(#`ticknum') ///
		ysc(range(`axismin',`axismax')) ///
		`yaxislab' ///
		`xaxistitle' ///
		title("`altmapname'", size(medsmall)) plotregion(margin(zero)) graphregion(margin(medium)) ///
		name(`altmap', replace)

		
	local++counter
	restore, preserve
}

graph combine `maps', rows(2) title("Seats by Popular Vote Margin", size(medium)) ///
note("Maps from FiveThirtyEight's Redistricting Atlas", size(*0.65)) ///
caption("@NathanLazarus3", size(vsmall) j(right) pos(5)) ///
name(combined, replace)

graph export graphs/multigraph.png, replace
