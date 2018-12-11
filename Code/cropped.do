//cropped.do

local marg = $marg
sort demshare
gen repneed = demshare //Repub would win the seat with >demshare
gen demneed = 100-repneed
/*gen demneed = .
gen popv = .
forvalues i=1/435{
	replace popv = max(0,min(100,demshare+50-demshare[`i']))
	sum popv [iw=totalvotes], meanonly
	replace demneed = r(mean) in `i'
}
gen repneed=100-demneed*/
sort repneed
gen repseats = _n
sort demneed
gen demseats = _n

local demgot = 50+`marg'
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
local demmarg = round(2*`marg',0.1)

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


gen proportional = repseats*100/435 if add==0
gen down = gotten - 7
gen and_tothe_right = popshare2018+0.5
gen left_alittle = popshare2018 - 0.45

local marginlimits = 20
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
replace repseats = r(max) in `emptyrow'
replace repneed = `upperlim' in `emptyrow'
replace repseats = r(min) in `emptyrow2'
replace repneed = `lowerlim' in `emptyrow2'

qui sum repseats if repseats>180
gen majoritylabel = "Majority (218)" if repseats == r(min)&add==0
gen proportionallabel = "Proportional" if repseats == r(min)&add==0

qui sum demneed if demneed>46&add==0
gen demlab = `"Democrats"' if demneed == r(min)&add==0
qui sum repneed if repneed>44&add==1
gen replab = `"Republicans"' if repneed == r(min)&add==1
gen majority = 218
local ticknum = 2*int(`marginlimits'/10)
local symbol = "pipe"
if c(version)<15 local symbol = "Oh"


twoway connected majority repneed, lcolor(sand) lwidth(medthin) mlabsize(small) m(none)|| ///
	connected proportionalseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) m(none) || ///
	connected repseats repneed, lcolor("220 34 34") lwidth(medthick) m(none) || ///
	connected demseats demneed, lcolor("22 107 170") lwidth(medthick) m(none) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(12) mlabsize(small) mlabcol("220 34 34") mlabgap(*.9) ///
	yscale(titlegap(*-6)) ylab(200 300, labsize(small)) xlab(40 "-20" 50 "0" 60 "+20%") ///
	xtick(#`ticknum') ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(5)) ///
	title("Seats by Popular Vote Margin") plotregion(margin(zero)) graphregion(margin(0 5 3 5)) ///
	/// note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Cropped, replace)

.Cropped.plotregion1.AddTextBox added_text editor 222.9 40.28
.Cropped.plotregion1.added_text[1].style.editstyle  size(small) color("219 112 41") horizontal(left) vertical(middle) margin(zero) box_alignment(east) editcopy
.Cropped.plotregion1.added_text[1].text = {}
.Cropped.plotregion1.added_text[1].text.Arrpush Majority (218)

.Cropped.plotregion1.AddTextBox added_text editor 192 40.27
.Cropped.plotregion1.added_text[2].style.editstyle  size(small) color(gs5) horizontal(left) vertical(middle) margin(zero)  box_alignment(east) editcopy
.Cropped.plotregion1.added_text[2].text = {}
.Cropped.plotregion1.added_text[2].text.Arrpush Proportional
.Cropped.drawgraph
	
graph export graphs/Cropped.png, replace

tempfile stuff  demlines
save `stuff'
keep demseats demneed
keep if demseats != .
save `demlines'
use `stuff'
keep repseats repneed
sort repneed repseats
keep if repseats != .
merge 1:1 _n using `demlines', nogen
sum repseats
replace repseats = r(max) if repseats == .
sum repneed
replace repneed = r(max) if repneed == .
sum demseats
replace demseats = r(max) if demseats == .
sum demneed
replace repneed = r(max) if repneed == .
export delim graphs/croppedlines.csv, replace
clear
use `stuff'

sum repseats
local min = r(min)
local max = r(max)
sum demseats
local min = min(`min',r(min))
local max = max(`max',r(max))

twoway ///connected majority repneed, lcolor(sand) lwidth(medthin) mlabsize(small) m(none)|| ///
	connected proportionalseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) m(none) yline(218, lcolor(sand)) || ///
	///connected repseats repneed, lcolor("220 34 34") lwidth(medthick) m(none) mlab(replab) mlabpos(10) mlabcolor("220 34 34*1.1") mlabgap(*.9) mlabsize(vsmall) || ///
	///connected demseats demneed, lcolor("22 107 170") lwidth(medthick) m(none) mlab(demlab) mlabpos(3) mlabcolor("22 107 170*1.1") mlabgap(*3) mlabsize(vsmall) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(12) mlabsize(small) mlabcol("220 34 34") mlabgap(*.9) ///
	yscale(range($axismin,$axismax) titlegap(*-6)) ylab(100 200 300, labsize(small)) ytick(`min' `max', add custom nolab tlcolor(lime)) xlab(40 "-20" 50 "0" 60 "+20%") ///
	xtick(#`ticknum') ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(5)) ///
	/*title("Seats by Popular Vote Margin")*/ plotregion(margin(zero)) graphregion(margin(0 5 0 2)) ///
	/// note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Cropped, replace)

.Cropped.plotregion1.AddTextBox added_text editor 222.9 40.28
.Cropped.plotregion1.added_text[1].style.editstyle  size(small) color("219 112 41") horizontal(left) vertical(middle) margin(zero) box_alignment(east) editcopy
.Cropped.plotregion1.added_text[1].text = {}
.Cropped.plotregion1.added_text[1].text.Arrpush Majority (218)

.Cropped.plotregion1.AddTextBox added_text editor 192 40.27
.Cropped.plotregion1.added_text[2].style.editstyle  size(small) color(gs5) horizontal(left) vertical(middle) margin(zero)  box_alignment(east) editcopy
.Cropped.plotregion1.added_text[2].text = {}
.Cropped.plotregion1.added_text[2].text.Arrpush Proportional
.Cropped.drawgraph

	
graph export graphs/Cropped.svg, replace
