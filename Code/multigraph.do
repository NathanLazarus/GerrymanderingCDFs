//multigraph.do

local marg = $marg
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

	reg demshare c.pvicurrent##c.pvicurrent##c.pvicurrent##c.pvicurrent if state != "PA"
	gen fakeshare = _b[_cons]+_b[pvicurrent]*pvi`altmap'+_b[c.pvicurrent#c.pvicurrent]*pvi`altmap'^2+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvi`altmap'^3+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvi`altmap'^4
	sum fakeshare [iw=totalvotes]
	//replace fakeshare = fakeshare-r(mean)+50

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


	gen repneed = demshare
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
	local axismin = min(`demmin',`repmin',`axismin')
	local axismax = max(`demmax',`repmax',`axismax')
	restore, preserve
}

local axismin = `axismin'-2 //for a little more room

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

	reg demshare pvicurrent if state!="PA"
	cv_regress //uses leave one out cross validation to select the degree of polynomial, up to order 4
	//The relationship between PVI and log odds is almost perfectly linear, so this matters a lot less than when the shifts were linear.
	//With linear shifts, it looked like dems were underperforming in the most and least democratic areas—why weren't they shifting by 3 points like everywhere else?
	local rmse = r(rmse)
	local order = 1
	local command = "c.pvicurrent##c.pvicurrent"
	forvalues x=2/4 {
		reg demshare `command' if state!="PA"
		cv_regress
		if `r(rmse)'<`rmse' local order = `x'
		local rmse = min(`rmse',`r(rmse)')
		local command = "`command'##c.pvicurrent"
	}
	
	global order = `order'
	
	replace pvicurrent = pvicurrent/50 //helps with orthoganalization, also just more logical units
	replace pvi`altmap'=pvi`altmap'/50 
	
	/* to visualize the PVI share relationship
	local lincons = _b[_cons]
	local lincoef = _b[pvicurrent]
	gen fakeshare1 = _b[pvicurrent]*pvi`altmap'+_b[_cons]
	reg demshare c.pvicurrent##c.pvicurrent##c.pvicurrent##c.pvicurrent if state != "PA"
	gen fakeshare4 = _b[_cons]+_b[pvicurrent]*pvi`altmap'+_b[c.pvicurrent#c.pvicurrent]*pvi`altmap'^2+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvi`altmap'^3+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvi`altmap'^4	
	gen fakeshare2test = _b[_cons]+_b[pvicurrent]*pvicurrent+_b[c.pvicurrent#c.pvicurrent]*pvicurrent^2+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvicurrent^3+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent#c.pvicurrent]*pvicurrent^4
	gen quarticresults = .
	forvalues i=-0.2(0.02)0.2{
		replace quarticresults = _b[pvicurrent]*`i'+_b[c.pvicurrent#c.pvicurrent]*`i'*`i'+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent]*`i'*`i'*`i'+_b[c.pvicurrent#c.pvicurrent#c.pvicurrent#c.pvicurrent]*`i'^4+_b[_cons] in `=50*`i'+50'
	}
	reg demshare c.pvicurrent##c.pvicurrent if state != "PA"
	gen fakeshare2 = _b[_cons]+_b[pvicurrent]*pvi`altmap'+_b[c.pvicurrent#c.pvicurrent]*pvi`altmap'*pvi`altmap'
	local quadcons=_b[_cons]
	local quadlin = _b[pvicurrent]
	local quadquad = _b[c.pvicurrent#c.pvicurrent]
	//sort fakeshare2test
	//graph twoway lfit demshare pvicu if state!="PA", lwidth(vthin) || qfit demshare pvicu if state!="PA", lwidth(vthin) || scatter fakeshare2test pvicu if state!="PA", msize(vsmall) || lowess demshare pvicu if state!="PA", lwidth(vthin) name("fits", replace)
	forvalues i=-0.2(0.02)0.2{
		local lin = `lincoef'*`i'+`lincons'
		local quad = `quadlin'*`i'+`quadquad'*`i'*`i'+`quadcons'
		local quart = quarticresults[`=50*`i'+50']
		di "at a PVI of `=50*`i'', the linear model gives `lin'. The quadratic model, on the other hand, gives `quad'. The quartic gives `quart'"
	}
	*/
	
	
	local power = "c.pvicurrent"
	local polycoef = "c.pvicurrent"
	local genstatement = "_b[_cons]+_b[pvicurrent]*pvi`altmap'"
	if `order'>1 forvalues a=2/`order' {
		local power = "`power'##c.pvicurrent"
		local polycoef = "`polycoef'#c.pvicurrent"
		local genstatement = "`genstatement'+_b[`polycoef']*pvi`altmap'^`a'"
	}
	reg demshare `power' if state != "PA"
	gen fakeshare = `genstatement'
	
	gen fakerepneed = fakeshare
	gen fakedemneed = 100-fakerepneed
	/*gen fakedemneed = .
	gen fakepopv = .
	forvalues i=1/435{
		replace fakepopv = max(0,min(100,fakeshare+50-fakeshare[`i']))
		sum fakepopv [iw=totalvotes], meanonly
		replace fakedemneed = r(mean) in `i'
	}
	gen fakerepneed=100-fakedemneed*/
	
	if "`altmap'" == "algorithmiccompact"|"`altmap'"=="Compact"{
		tempfile everything
		save `everything'
		gen `altmap'win2018 = fakedemneed<(`marg'+50)
		tempfile `altmap'stateresults
		collapse (sum) `altmap'win2018, by(v1)
		save ``altmap'stateresults'
		use `everything'
	}
	
	
	if "`counter'" == "1"{
		//get outcome under current districts, but comparing apples to apples by using their PVI instead of actual results
		local polycoef = "c.pvicurrent"
		local genstatement = "_b[_cons]+_b[pvicurrent]*pvicurrent"
		if `order'>1 forvalues a=2/`order' {
			local polycoef = "`polycoef'#c.pvicurrent"
			local genstatement = "`genstatement'+_b[`polycoef']*pvi`altmap'^`a'"
		}
		gen currentshare = `genstatement'
		gen currentrepneed = currentshare
		gen currentdemneed = 100-currentrepneed
		tempfile everything2
		save `everything2'
		gen win2018 = currentdemneed<(`marg'+50)
		tempfile stateresults
		collapse (sum) win2018, by(v1)
		save `stateresults'
		use `everything2'
	}
	
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


	gen repneed = demshare
	gen demneed = 100-repneed	
	/*gen demneed = .
	gen popv = .
	forvalues i=1/435{
		replace popv = max(0,min(100,demshare+50-demshare[`i']))
		sum popv [iw=totalvotes], meanonly
		replace demneed = r(mean) in `i'
	}
	gen repneed=100-demneed*/
	
	if "`altmap'" == "algorithmiccompact"{
		tempfile everything3
		save `everything3'
		gen actualwin2018 = demneed<(`marg'+50)
		tempfile actualstateresults
		collapse (sum) actualwin2018, by(v1)
		save `actualstateresults'
		use `everything3'
	}
	
	sort repneed
	gen repseats = _n
	sort demneed
	gen demseats = _n
	
	gen sortorder = _n
	drop fake*
	merge 1:1 sortorder using `fake', nogen
	
	local demgot = 50+`marg'
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
	
	
	if "`altmap'" == "Compact" {
		sum fakedemneed if fakedemseats == 218
		global compactdemmaj = r(mean)
	}
	
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
	gen down = gotten - 8.75
	gen and_tothe_right = popshare2018+1.25
	gen left_alittle = popshare2018 - 0.5
	gen left_alittlemore = popshare2018
	gen majority = 218
	
	local demmarkerloc=3
	local replabgap=1
	local demlabsize = "mlabsize(*0.975)"
	if "`altmap'" == "Dem" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*1.5 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.075 if inrange(fakedemseats,161,175)&add==0
		local demmarkerloc=1
		
		local demlabsize = "mlabsize(*.925)"
		
		gen repx = popshare2018-0.25
		gen repy = wouldvegotten-3.75
	}
	if "`altmap'" == "Proportional" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.875 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.225 if inrange(fakedemseats,161,175)&add==0

		local demlabsize = "mlabsize(*.925)"

		local replabgap=.6
		gen repx = popshare2018
		gen repy = wouldvegotten
	}
	if "`altmap'" == "Compact" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.95 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.2 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018-0.1
		gen repy = wouldvegotten+1.5
	}
	if "`altmap'" == "GOP"{
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.45 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.13 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018
		gen repy = wouldvegotten
		local replabgap=.6
		
		replace and_tothe_right = popshare2018+0.65
		replace down = gotten - 9.5
		local demlabsize = "mlabsize(*.8)"
	}
	if "`altmap'" == "Competitive"{
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.5 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.13 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018+1.675
		gen repy = wouldvegotten+9.5
	}
	if "`altmap'" == "algorithmiccompact" {
		gen fakeline = `fakegotten'+(fakedemseats-161)*0.95 if inrange(fakedemseats,161,175)&add==0
		gen fakelinex = `demgot'+(fakedemseats-161)*0.205 if inrange(fakedemseats,161,175)&add==0
			
		gen repx = popshare2018+0.9
		gen repy = wouldvegotten+12.25
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
	local demmarg = round(2*`marg',0.01)
	
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
	
	
			
	twoway /// scatter fakegotten popshare2018, m(none) mcol(gs8) msize(small) || ///
		connected majority repneed, lcolor(sand) lwidth(medthin) m(none)|| ///
		connected repseats proportional, lwidth(medthin) lpattern("shortdash") lcolor(gs5) m(none) || ///
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

		
	if "`altmap'"=="Compact"|"`altmap'"=="Proportional"|"`altmap'"=="Competitive" {
	
		local altmapname2 = "`altmapname'"
		if "`altmap'"=="Compact" local altmapname2= "Compact Districts, Following County Borders"

			
		local fakelabgap = 0.5
		local fakelabloc = 4
		if "`altmap'"=="Compact" {

			replace fakeline = `fakegotten'+(fakedemseats-161)*0.7 if inrange(fakedemseats,161,175)&add==0
			replace fakelinex = `demgot'+(fakedemseats-161)*0.18 if inrange(fakedemseats,161,175)&add==0
			replace repx = popshare2018-0.2
			replace repy = wouldvegotten+1.5
			local replabgap=1.25
			
			replace and_tothe_right = popshare2018+0.58
			replace down = gotten - 7
			
			qui sum fakedemneed if fakedemneed>46.8&add==0
			gen fakelab = `"`altmap' Districts"' if fakedemneed == r(min)&add==0
			qui sum demneed if demneed>50.3&add==0
			gen actuallab = `"Actual Districts"' if demneed == r(min)&add==0
					
			sum fakeline
			local liny = r(max)
			sum fakelinex
			local linx = r(max)
		}

		if "`altmap'"=="Proportional" {
			replace fakeline = `fakegotten'+(fakedemseats-161)*0.4 if inrange(fakedemseats,161,175)&add==0
			replace fakelinex = `demgot'+(fakedemseats-161)*0.17 if inrange(fakedemseats,161,175)&add==0
			replace repx = popshare2018+0.1
			replace repy = wouldvegotten+0.1
			local replabgap=1.25
			
			replace and_tothe_right = popshare2018+0.56
			replace down = gotten - 6.2
			
			qui sum fakedemneed if fakedemneed>41.3&add==0
			gen fakelab = `"`altmapname2' Districts"' if fakedemneed == r(min)&add==0
			qui sum demneed if demneed>50.3&add==0
			gen actuallab = `"Actual Districts"' if demneed == r(min)&add==0
					
			sum fakeline
			local liny = r(max)
			sum fakelinex
			local linx = r(max)
		}

		if "`altmap'"=="Competitive" {
			replace fakeline = `fakegotten'+(fakedemseats-161)*0.5 if inrange(fakedemseats,161,175)&add==0
			replace fakelinex = `demgot'+(fakedemseats-161)*0.09 if inrange(fakedemseats,161,175)&add==0
			replace repx = popshare2018+0.1
			replace repy = wouldvegotten+0.1
			local replabgap=1.25
			
			replace and_tothe_right = popshare2018+0.56
			replace down = gotten - 6.2
			
			qui sum fakedemneed if fakedemneed>44.9&add==0
			gen fakelab = `"`altmapname2' Districts"' if fakedemneed == r(min)&add==0
			qui sum demneed if demneed>50.3&add==0
			gen actuallab = `"Actual Districts"' if demneed == r(min)&add==0
					
			sum fakeline
			local liny = r(max)
			sum fakelinex
			local linx = r(max)
			local fakelabloc = 4
			local fakelabgap = 1
		}
		local label100 = ""
		if "`altmap'"=="Proportional"|"`altmap'"=="Competitive"{
			local label100 = "100"
		}
		local range = ""
		if "`altmap'"=="Proportional"{
			local range = "yscale(range(86,349))"
		}




		twoway scatter fakegotten popshare2018, m(none) mcol(gs8) msize(small) || ///
		connected majority repneed, lcolor(sand) lwidth(medthin) m(none)|| ///
		connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.5) mlabcol(gs5) || ///
		line repseats repneed, lcolor("220 34 34*.36") || ///
		connected demseats demneed, lcolor("22 107 170*.36") m(none) mlab(actuallab) mlabpos(4) mlabcolor("22 107 170*.4") mlabgap(*.5) mlabsize(*.95)|| ///
		line fakerepseats fakerepneed, lcolor("220 34 34") || ///
		connected fakedemseats fakedemneed, lcolor("22 107 170") m(none) mlab(fakelab) mlabpos(`fakelabloc') mlabcolor("22 107 170*1.1") mlabgap(*`fakelabgap') mlabsize(*.95)|| ///
		line fakeline fakelinex, lcolor(black) lwidth(vthin) || ///
		scatteri `liny' `linx' (`demmarkerloc') "`fakegotten'", m(none) mlabsize(small) mlabcol("22 107 170") mlabgap(*0.2) || ///
		scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170*.6") || ///
		scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter repy repx, m(none) mlab(wouldvegotten) mlabpos(10) mlabsize(small) mlabcol("220 34 34*.6") mlabgap(*`replabgap') ///
		ylab(`label100' 200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%  ") ///
		xtick(#`ticknum') ///
		`range' ///
		ylab(245 "Seats", add custom notick labsize(medsmall) labgap(*7)) ///
		xtitle("Popular Vote Margin", height(4)) ///
		title("`altmapname2'", size(medsmall)) plotregion(margin(zero)) graphregion(margin(medium)) ///
		name(`altmap'png, replace)
		
		graph export graphs/`altmap'.png, width(8000) replace
		
		if "`altmap'"=="Compact" {
			tempfile things integrationvals
			save `things'
			clear
			set seed 1048576
			local thisyear = 50+`marg'
			local pastvals = "53 53.3 53.1 52.6 50.1 50.1 50.3 51.5 50.7 53.6 54.7 52.6 51.1 52.4 50.8"
			local valcount = 1
			set obs 15
			gen x = .
			foreach pastval of local pastvals {
			replace x = `pastval' in `valcount'
			local ++valcount
			}
			sum
			describe
			set obs `=_N+1'
			replace x = `thisyear' in `=_N'
			sum x
			local sd = r(sd)
			expand 10000
			gen got = x+`sd'/sqrt(15)*rt(15)
			replace got = 50 + abs(got-50)
			sum got
			local max = r(max)
			keep got
			save `integrationvals'
			use `things'
			stack fakedemneed fakedemseats fakedemseats fakerepseats fakedemneed fakerepneed /**/ fakerepneed fakerepseats fakedemseats fakerepseats fakedemneed fakerepneed, into(need seats demseats repseats demneed repneed) clear
			rename _stack party
			sum need if need<50
			sum seats if need>r(max)
			keep if seats>`=r(min)-2'
			gen otherpartyseats = .
			forvalues i=1/`=_N' {
				sum seats if need<need[`i']&party!=party[`i']
				replace otherpartyseats = r(max) in `i'
			}
			gen demneedifrepwin = .
			gen repneedifdemwin = .
			forvalues i=1/`=_N' {
			if party[`i']==1 {
				sum repneed if repseats == seats[`i']
				replace repneedifdemwin = r(mean) in `i'
				sum demneed if demseats == otherpartyseats[`i']
				replace demneedifrepwin = r(mean) in `i'
			}
			if party[`i']==2 {
				sum demneed if demseats == seats[`i']
				replace demneedifrepwin = r(mean) in `i'
				sum repneed if repseats == otherpartyseats[`i']
				replace repneedifdemwin = r(mean) in `i'
			}
			}
			gen seatgap = otherpartyseats-seats
			replace seatgap = -seatgap if party == 1
			gen votegap = (demneedifrepwin/*-got+got*/-repneedifdemwin)/2
			keep if need<=`max'
			keep need seatgap votegap
			keep if seatgap != .
			cross using `integrationvals'
			keep if got>need
			gsort got
			bys got: egen max = max(need)
			keep if need == max
			sum seatgap
			global compactaverageseatgap = r(mean)
			sum votegap
			global compactaveragevotegap = 2*r(mean)
			clear
			
			
			use `things'
		}

		
		tempfile stuff demlines
		save `stuff'
		keep fakedemseats fakedemneed
		keep if fakedemseats!=.
		save `demlines'
		use `stuff'
		keep fakerepseats fakerepneed
		sort fakerepneed fakerepseats
		keep if fakerepseats!=.
		merge 1:1 _n using `demlines', nogen
		sum fakerepseats
		replace fakerepseats = r(max) if fakerepseats == .
		sum fakerepneed
		replace fakerepneed = r(max) if fakerepneed == .
		sum fakedemseats
		replace fakedemseats = r(max) if fakedemseats == .
		sum fakedemneed
		replace fakerepneed = r(max) if fakerepneed == .		
		rename fake* *
		export delim graphs/`altmap'lines.csv, replace
		clear
		use `stuff'

		sum repseats
		local min = r(min)
		local max = r(max)
		sum demseats
		local min = min(`min',r(min))
		local max = max(`max',r(max))
		sum fakerepseats
		local min = min(`min',r(min))
		local max = max(`max',r(max))
		sum fakedemseats
		local min = min(`min',r(min))
		local max = max(`max',r(max))
		local axismin = `min'-8
		if "`altmap'"=="Proportional"|"`altmap'"=="Competitive"{ //getting proportional and competitive on the same axis
			local axismin = 70
		}
		local axismax = `max'+3
		if "`altmap'"=="Proportional" {
			local axismax = 352
		}

/*twoway ///connected majority repneed, lcolor(sand) lwidth(medthin) mlabsize(small) m(none)|| ///
	connected proportionalseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) m(none) yline(218, lcolor(sand)) || ///
	///connected repseats repneed, lcolor("220 34 34") lwidth(medthick) m(none) mlab(replab) mlabpos(10) mlabcolor("220 34 34*1.1") mlabgap(*.9) mlabsize(vsmall) || ///
	///connected demseats demneed, lcolor("22 107 170") lwidth(medthick) m(none) mlab(demlab) mlabpos(3) mlabcolor("22 107 170*1.1") mlabgap(*3) mlabsize(vsmall) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(12) mlabsize(small) mlabcol("220 34 34") mlabgap(*.9) ///
	yscale(range(`axismin',`axismax') titlegap(*-6)) ylab(200 300, labsize(small)) ytick(`min' `max', add custom nolab tlcolor(lime)) xlab(40 "-20" 50 "0" 60 "+20%") ///
	xtick(#`ticknum') ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(5)) ///
	/*title("Seats by Popular Vote Margin")*/ plotregion(margin(zero)) graphregion(margin(0 5 0 2)) ///
	/// note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Cropped, replace)*/
		
		twoway ///scatter fakegotten popshare2018, m(none) mcol(gs8) msize(small) || ///
		///connected majority repneed, lcolor(sand) lwidth(medthin) m(none)|| ///
		connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) m(none) yline(218, lcolor(sand)) || ///
		line repseats repneed, lcolor("220 34 34*.36") || ///
		connected demseats demneed, lcolor("22 107 170*.36") m(none) mlab(actuallab) mlabpos(4) mlabcolor("22 107 170*.4") mlabgap(*.5) mlabsize(*1.1)|| ///
		line fakerepseats fakerepneed, lcolor("220 34 34") || ///
		connected fakedemseats fakedemneed, lcolor("22 107 170") m(none) mlab(fakelab) mlabpos(`fakelabloc') mlabcolor("22 107 170*1.1") mlabgap(*`fakelabgap') mlabsize(*1.1)|| ///
		line fakeline fakelinex, lcolor(black) lwidth(vthin) || ///
		scatteri `liny' `linx' (`demmarkerloc') "`fakegotten'", m(none) mlabsize(small) mlabcol("22 107 170") mlabgap(*0.2) || ///
		scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170*.6") || ///
		scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter repy repx, m(none) mlab(wouldvegotten) mlabpos(10) mlabsize(small) mlabcol("220 34 34*.6") mlabgap(*`replabgap') ///
		ylab(100 200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%  ") ///
		xtick(#`ticknum') ///
		yscale(range(`axismin',`axismax')) ///
		ylab(245 "Seats", add custom notick labsize(medsmall) labgap(*7)) ///
		ytick(`min' `max', add custom nolab tlcolor(lime)) ///
		xtitle("Popular Vote Margin", height(4)) ///
		/*title("Compact Districts, Following County Borders", size(medsmall))*/ plotregion(margin(zero)) graphregion(margin(0 5 0 2)) ///
		name(`altmap'svg, replace)
		
		graph export graphs/`altmap'.svg, replace

		//here's the SVG as a PNG, without the green ticks that I use to align the SVGs and then remove
		twoway ///scatter fakegotten popshare2018, m(none) mcol(gs8) msize(small) || ///
		///connected majority repneed, lcolor(sand) lwidth(medthin) m(none)|| ///
		connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) m(none) yline(218, lcolor(sand)) || ///
		line repseats repneed, lcolor("220 34 34*.36") || ///
		connected demseats demneed, lcolor("22 107 170*.36") m(none) mlab(actuallab) mlabpos(4) mlabcolor("22 107 170*.4") mlabgap(*.5) mlabsize(*1.1)|| ///
		line fakerepseats fakerepneed, lcolor("220 34 34") || ///
		connected fakedemseats fakedemneed, lcolor("22 107 170") m(none) mlab(fakelab) mlabpos(`fakelabloc') mlabcolor("22 107 170*1.1") mlabgap(*`fakelabgap') mlabsize(*1.1)|| ///
		line fakeline fakelinex, lcolor(black) lwidth(vthin) || ///
		scatteri `liny' `linx' (`demmarkerloc') "`fakegotten'", m(none) mlabsize(small) mlabcol("22 107 170") mlabgap(*0.2) || ///
		scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170*.6") || ///
		scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
		scatter repy repx, m(none) mlab(wouldvegotten) mlabpos(10) mlabsize(small) mlabcol("220 34 34*.6") mlabgap(*`replabgap') ///
		ylab(100 200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%  ") ///
		xtick(#`ticknum') ///
		yscale(range(`axismin',`axismax')) ///
		ylab(245 "Seats", add custom notick labsize(medsmall) labgap(*7)) ///
		xtitle("Popular Vote Margin", height(4)) ///
		/*title("Compact Districts, Following County Borders", size(medsmall))*/ plotregion(margin(zero)) graphregion(margin(0 5 0 2)) ///
		name(`altmap'InteractivePNG, replace)
		
		graph export graphs/`altmap'Interactive.png, width(8000) replace
		
		
	}
	
	local++counter
	restore, preserve

}


graph combine `maps', rows(2) title("Seats by Popular Vote Margin", size(medium)) ///
note("Maps from FiveThirtyEight's Redistricting Atlas", size(*0.65)) ///
///caption("@NathanLazarus3", size(vsmall) j(right) pos(5)) ///
name(combined, replace)

graph export graphs/multigraph.png, width(8000) replace

clear
use `stateresults'
merge 1:1 v1 using `algorithmiccompactstateresults', nogen
merge 1:1 v1 using `Compactstateresults', nogen
merge 1:1 v1 using `actualstateresults', nogen

replace win2018 = win2018+1 if v1=="Utah"|v1=="Pennsylvania"|v1=="South Carolina"
//this is the worst thing I've had to do, and I really wish I had the geographic data right now.
//PVI makes pretty accurate predictions: it's off by 14 districts in 13 states (and 538 has the old PA districts).
//But it thinks a Democrat shouldn't have won in Oklahoma. If I use the actual results, then, Oklahoma is "gerrymandered" for Democrats.
//That's clearly wrong, so I'm using the districts' PVI to guess the results. But it gives Democrats 232 seats, and says, for example,
//that Democrats "should" get a seat in Utah. But they did!
gen compactdiff = win2018-Compactwin2018
gen algorithmiccompactdiff = win2018-algorithmiccompactwin2018

keep if compactdiff!=0|algorithmiccompactdiff!=0
sort compactdiff algorithmiccompactdiff
separate compactdiff, by(compactdiff<0)
separate algorithmiccompactdiff, by(algorithmiccompactdiff<0)
replace compactdiff1 = abs(compactdiff1)
replace algorithmiccompactdiff1 = abs(algorithmiccompactdiff1)
gen state = _n
labmask state, val(v1)
graph hbar compactdiff0 compactdiff1 algorithmiccompactdiff0 algorithmiccompactdiff1, over(state, label(labsize(vsmall)) gap(*2)) ///
	bar(1, color("22 107 170*1.1")) bar(3, color("22 107 170*.36")) bar(2, color("220 34 34*1.1"))  bar(4, color("220 34 34*.36")) ///
	bargap(0) nofill ysc(range(0,1)) ylab(0 2 4) ytitle("Seats", orientation(horizontal)) ///
	plotregion(margin(zero)) graphregion(margin(medium)) ///
	legend(on order(2 " " "County" "Borders" "(Square)" " " 4 "Ignore" "County" "Borders" "(Circular)") ring(0) cols(1) pos(3) symxsize(*0.5) symysize(*0.5) region(lwidth(none)) size(small)) ///
	name(stategerrymander, replace)

graph export graphs/stategerrymander.png, width(8000) replace

