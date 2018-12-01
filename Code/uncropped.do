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

twoway connected majority repneed, lcolor(sand) lwidth(medthin) mlab(majoritylabel) m(none) mlabpos(2) mlabgap(*2.05) mlabcol("219 112 41") || ///
	connected repseats proportional, lwidth(medthin) lpattern(dash) lcolor(gs5) mlab(proportionallabel) m(none) mlabpos(11) mlabgap(*.5) mlabcol(gs5) || ///
	connected repseats repneed, lcolor("220 34 34") m(none) mlab(replab) mlabpos(3) mlabcolor("220 34 34*1.1") mlabgap(*1.8) mlabsize(vsmall) || ///
	connected demseats demneed, lcolor("22 107 170") m(none) mlab(demlab) mlabpos(9) mlabcolor("22 107 170*1.1") mlabgap(*3.5) mlabsize(vsmall) || ///
	scatter gotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter down and_tothe_right, m(none) mlab(gotten) mlabpos(0) mlabsize(small) mlabcol("22 107 170") || ///
	scatter wouldvegotten popshare2018, m(`symbol') mcol(black) msize(medsmall) || ///
	scatter wouldvegotten left_alittle, m(none) mlab(wouldvegotten) mlabpos(11) mlabsize(small) mlabcol("220 34 34") mlabgap(*.6) ///
	yscale(titlegap(*-6)) ylab(100 200 300 400, labsize(small)) xlab(0 "-100" 25 "-50" 50 "0" 75 "50" 100 "100%") ///
	xtick(0(12.5)100) ///
	ytitle("Seats", height(-8) orientation(horizontal) size(small)) xtitle("Popular Vote Margin", height(7)) ///
	title("Seats by Popular Vote Margin") plotregion(margin(zero)) graphregion(margin(medlarge)) ///
	note("Democrats won `gotten' seats with a popular vote margin of `demmarg'%.""Republicans could've won `gotten' seats with just `repmarg'%.""With `demmarg'%, Republicans would've won `wouldvegotten'.", size(vsmall) span) ///
	///caption("@NathanLazarus3", size(vsmall) j(right) pos(5) ring(3)) ///
	name(Uncropped, replace)

	
graph export graphs/Uncropped.png, replace	
