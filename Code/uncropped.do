//uncropped.do

local marg = $marg
gen repneed = demshare //Repub would win the seat with >demshare
gen demneed = 100-repneed
/*gen demneed = . This was for the linear model (to censor vote shares at 100), and is rendered obsolete by log odds
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

sum demneed if demneed<50
global ifeven = r(N)
sum demneed if demneed<75
global dem75 = 435-r(N)
sum repneed if repneed<75
global rep75 = 435-r(N)
list if demseats == 218
sum demneed if demseats == 218
global demmaj = round(r(mean),0.001)


//gets average differences between D and R at the same level of votes/seats
tempfile things integrationvals
save `things'
clear
set seed 1048576
local thisyear = 50+`marg'
input x
53
53.3
53.1
52.6
50.1 //actually 49.9
50.1
50.3
51.5
50.7
53.6
54.7
52.6
51.1 //actually 48.9
52.4
50.8
end
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
stack demneed demseats demseats repseats demneed repneed /**/ repneed repseats demseats repseats demneed repneed, into(need seats demseats repseats demneed repneed)
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
global averageseatgap = r(mean)
sum votegap
global averagevotegap = 2*r(mean)
clear


use `things'


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
gen proportionallabel = "Proportional" if repseats ==64&add==0

gen down = gotten - 6
gen and_tothe_right = popshare2018+3.1
gen left_alittle = popshare2018 - 0.2
gen majority = 218
gen majoritylabel = "Majority (218)" if repneed==0


qui sum demneed if demneed>32&add==0
gen demlab = `"Democrats"' if demneed == r(min)&add==0
qui sum repneed if repneed>30&add==0
gen replab = `"Republicans"' if repneed == r(min)&add==0
local symbol = "pipe"
if c(version)<15 local symbol = "Oh"

tempfile stuff  demlines
save `stuff'
keep demseats demneed
save `demlines'
use `stuff'
keep repseats repneed
sort repneed repseats
merge 1:1 _n using `demlines', nogen
export delim graphs/uncroppedlines.csv, replace
clear
use `stuff'

twoway connected majority repneed, lcolor(sand) lwidth(medthin) mlab(majoritylabel) m(none) mlabpos(2) mlabgap(*2.05) mlabcol("219 112 41") || ///
	connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.5) mlabcol(gs5) || ///
	connected repseats repneed, lcolor("220 34 34") m(none) mlab(replab) mlabpos(3) mlabcolor("220 34 34*1.1") mlabgap(*2) mlabsize(*.9) || ///
	connected demseats demneed, lcolor("22 107 170") m(none) mlab(demlab) mlabpos(9) mlabcolor("22 107 170*1.1") mlabgap(*3) mlabsize(*.9) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(11) mlabsize(small) mlabcol("220 34 34") mlabgap(*.6) ///
	yscale(titlegap(*-6)) ylab(100(100)400, labsize(small)) ytick(435, add custom nolab tlcolor(white)) xlab(0 "-100" 25 "-50" 50 "0" 75 "50" 100 "+100% ") ///
	xtick(0(12.5)100) ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(7)) ///
	title("Seats by Popular Vote Margin") plotregion(margin(zero)) graphregion(margin(0 5 3 5)) ///
	///note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Uncropped, replace)

graph export graphs/Uncropped.png, width(8000) replace

twoway /*connected majority repneed, lcolor(sand) lwidth(medthin) mlab(majoritylabel) m(none) mlabpos(2) mlabgap(*2.05) mlabcol("219 112 41") ||*/ ///
	scatter majority repneed, m(none) mlab(majoritylabel) mlabpos(2) mlabgap(*2.05) mlabcol("219 112 41") yline(218, lcolor(sand)) || ///
	connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.5) mlabcol(gs5) || ///
	connected repseats repneed, lcolor("220 34 34") m(none) mlab(replab) mlabpos(3) mlabcolor("220 34 34*1.1") mlabgap(*2) mlabsize(*.9) || ///
	connected demseats demneed, lcolor("22 107 170") m(none) mlab(demlab) mlabpos(9) mlabcolor("22 107 170*1.1") mlabgap(*3) mlabsize(*.9) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(11) mlabsize(small) mlabcol("220 34 34") mlabgap(*.6) ///
	yscale(range(-30,440) titlegap(*-6)) ylab(0(100)400, labsize(small)) ytick(435, add custom nolab tlcolor(lime)) xlab(0 "-100" 25 "-50" 50 "0" 75 "50" 100 "+100% ") ///
	xtick(0(12.5)100) ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(7)) ///
	/*title("Seats by Popular Vote Margin")*/ plotregion(margin(zero)) graphregion(margin(0 5 0 2)) ///
	///note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Uncropped, replace)

	
graph export graphs/Uncropped.svg, replace

global note = "Democrats won `gotten' seats with a popular vote margin of `demmarg'%. Republicans could've won `gotten' seats with just `repmarg'%. With `demmarg'%, Republicans would've won `wouldvegotten'."
