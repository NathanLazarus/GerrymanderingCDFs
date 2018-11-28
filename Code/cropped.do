//cropped.do

local shift = $shift
gen repneed = demshare //Repub would win the seat with >demshare
gen demneed = 100-repneed
sort repneed
gen repseats = _n
sort demneed
gen demseats = _n


local demgot = 50+`shift'
gen gotten = demneed<=`demgot'
gen popshare2018 = `demgot' in 1
qui sum gotten
replace gotten = .
replace gotten = r(sum) in 1
gen wouldvegotten = repneed<=`demgot'
qui sum wouldvegotten
replace wouldvegotten = .
replace wouldvegotten = r(sum) in 1

gen goodmargin = repneed-demneed
sum gotten
local gotten = r(mean)
sum wouldvegotten
local wouldvegotten = r(mean)
sum goodmargin if repseats==`gotten'
local repmarg = round(r(mean),0.1)
if inrange(`repmarg',0,0.99) local repmarg =  "0`repmarg'"
if inrange(`repmarg',-0.99,-0) {
local repmarg =  abs(`repmarg')
local repmarg= "-0`repmarg'"
}
local demmarg = round(2*`shift',0.1)

expand 2, gen(add)
replace demseats=demseats-add
replace repseats=repseats-(1-add)
sort demneed demseats

set obs `=_N+2'
replace repseats = 0 in `=_N-1'
replace demseats = 435 in `=_N-1'
replace repneed = 0 in `=_N-1'
replace demneed = 100 in `=_N-1'
replace repseats = 435 in `=_N'
replace demseats = 0 in `=_N'
replace repneed = 100 in `=_N'
replace demneed = 0 in `=_N'
sort demneed demseats


gen proportional = repseats*100/435 if add==0 // if fakerepseats!=0&fakedemseats!=0
gen down = gotten - 7
gen and_tothe_right = popshare2018+0.8
gen left_alittle = popshare2018 - 0.7

local marginlimits = 32
local lowerlim = 50-`marginlimits'/2
local upperlim = 50+`marginlimits'/2
replace proportional = . if !inrange(proportional,`lowerlim',`upperlim')
gen proportionalseats = repseats if proportional != .
replace repneed = . if !inrange(repneed,`lowerlim',`upperlim')
replace repseats = . if repneed == .
replace demneed = . if !inrange(demneed,`lowerlim',`upperlim')
replace demseats = . if demneed == .
set obs `=_N+2'
gen emptyfinder=_n
qui sum emptyfinder if demseats==.&repseats==.&proportional==.
local emptyrow = r(min)
local emptyrow2 = r(max)
qui sum demseats
replace demseats = r(min) in `emptyrow'
replace demneed = `lowerlim' in `emptyrow'
replace demseats = r(max) in `emptyrow2'
replace demneed = `upperlim' in `emptyrow2'
qui sum repseats
gen majoritylabel = "Majority (218)" if repseats == r(min)
replace repseats = r(max) in `emptyrow'
replace repneed = `upperlim' in `emptyrow'
replace repseats = r(min) in `emptyrow2'
replace repneed = `lowerlim' in `emptyrow2'

qui sum demneed if demneed>39.9&add==0
gen demlab = `"Democrats"' if demneed == r(min)&add==0
qui sum repneed if repneed>38.4&add==1
gen replab = `"Republicans"' if repneed == r(min)&add==1
gen proportionallabel = "Proportional" if repseats ==170
gen majority = 218
local ticknum = 2*int(`marginlimits'/10)
local symbol = "pipe"
if c(version)<15 local symbol = "Oh"

twoway connected proportionalseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.8) mlabcol(gs5) || ///
	connected majority repneed, lcolor(sand) lwidth(medthin) mlab(majoritylabel) m(none) mlabpos(2) mlabgap(*3) mlabcol("219 112 41") || ///
	connected repseats repneed, lcolor("220 34 34") lwidth(medthick) m(none) mlab(replab) mlabpos(10) mlabcolor("220 34 34*1.1") mlabgap(*.8) mlabsize(vsmall) || ///
	connected demseats demneed, lcolor("22 107 170") lwidth(medthick) m(none) mlab(demlab) mlabpos(3) mlabcolor("22 107 170*1.1") mlabgap(*1) mlabsize(vsmall) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(12) mlabsize(small) mlabcol("220 34 34") mlabgap(*.9) ///
	yscale(titlegap(*-6)) ylab(100 200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%") ///
	xtick(#`ticknum') ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(5)) ///
	title("Seats by Popular Vote Margin") plotregion(margin(zero)) graphregion(margin(medlarge)) ///
	note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Cropped, replace)
	
graph export graphs/Cropped.png, replace
