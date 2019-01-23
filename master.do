//master.do

clear all
cd ~/GerrymanderingCDFs
set scheme uncluttered
//(see https://github.com/graykimbrough/uncluttered-stata-graphs)
//ssc install _gwtmean
//ssc install cv_regress

import delim data/HousePopularVote.csv, clear
drop if _n<4
destring v12, gen(margin) percent
replace margin = margin*100
gen voteshare=(margin+100)/2
destring v13, gen(clintonmargin) percent
replace clintonmargin = clintonmargin*100
gen clintonshare=(clintonmargin+100)/2
local share2016 = 100*65853625/(65853625+62985106)-50
gen demean_2016= clintonshare-`share2016'
destring v6, gen(demvotes) ignore(",")
destring v7, gen(repvotes) ignore(",")
destring v8, gen(othervotes) ignore(",")

//this part deals with the uncontested races

replace repvotes = 0 if v4=="Ruben Gallego"
replace margin = 100 if v4=="Ruben Gallego"
replace voteshare = 100 if v4=="Ruben Gallego" //with apologies to the write in campaign of James "007" Bond IV

destring v15, gen(votes2016) ignore(",")
destring v16, gen(votes_vs2016) percent
gen totalvotes = demvotes+repvotes
gen weightedturnout = sqrt(totalvotes*votes2016) //shift calculated with a Fisher ideal index
bysort v1: egen state_turnout_decline = wtmean(votes_vs2016), weight(weightedturnout)
replace totalvotes = votes2016*state_turnout_decline if totalvotes == 0 //Florida
gen contested_dem = demvotes if demvotes!=0&repvotes!=0
gen contested_rep = repvotes if demvotes!=0&repvotes!=0
gen demshare_ifcontested = 100*contested_dem/(contested_dem+contested_rep)
gen contested = demshare_ifcontested!=.

sum demshare_ifcontested [iw=totalvotes]
local contested_share = r(mean)
sum clintonshare if contested==1 [iw=totalvotes]
local contested_share2016 = r(mean)
local shift = `contested_share'-`contested_share2016'
gen demshare = demshare_ifcontested if contested == 1

gen logclintonshare = log(clintonshare/(100-clintonshare))
local shiftnec = 0
gen shiftedclintonshare = clintonshare
sum shiftedclintonshare if contested == 1 [iw=totalvotes]
local value = -abs(r(mean)-`contested_share')
forvalues digit=1/15{
	local digitval = 0
	forvalues x = 1/9{
		local try = `shiftnec'+`x'*10^-`digit'
		di "`x'*10^-`digit'"
		replace shiftedclintonshare = exp(logclintonshare+`try')/(1+exp(logclintonshare+`try'))*100
		sum shiftedclintonshare if contested == 1 [iw=totalvotes]
		local tryvalue = r(mean)-`contested_share'
		if `tryvalue'>`value'&`tryvalue'<0 local digitval = `x'*10^-`digit'
		if `tryvalue'>`value'&`tryvalue'<0 local value = `tryvalue'
	}
	local shiftnec = `shiftnec'+`digitval'
}

replace shiftedclintonshare = exp(logclintonshare+`shiftnec')/(1+exp(logclintonshare+`shiftnec'))*100
sum shiftedclintonshare if contested == 1 [iw=totalvotes]
replace demshare = shiftedclintonshare if contested == 0
gen empiricaldemshare = demshare

//done dealing with uncontested races!

//testing the assumption of linearity in log odds
/*
I'm sure there's some way to do a hypothesis test of linearity in log odds (prediction RMSE?), but it's not what follows.
I can tell you that the shift from 2016 to 2018 necessary to generate a popular vote swing of 6.5% (shiftnec) is 0.11698 log odds points,
while the shift observed (shift_obs) was 0.11649, which seems pretty good.
If it were linear, the average log odds shift would be 0.12173*/

gen logdemshare_ifcontested = log(demshare_ifcontested/(100-demshare_ifcontested))
sum logdemshare_ifcontested [iw=totalvotes]
local log_contested_share = r(mean)
sum logclintonshare if contested == 1 [iw=totalvotes]
local shift_obs = `log_contested_share'-r(mean)

gen iflin = clintonshare+`shift' if contested == 1
gen lin_logdemshare_ifcontested = log(iflin/(100-iflin))
sum lin_logdemshare_ifcontested [iw=totalvotes]
local lin_log_contested_share = r(mean)
sum logclintonshare if contested == 1 [iw=totalvotes]
local shift_lin = `lin_log_contested_share'-r(mean)

di "linear in percentages: `shift_lin', observed: `shift_obs', linear in log odds: `shiftnec'"


sum demshare [iw=totalvotes]
global marg = r(mean)-50

local compositionaleffect = (`r(mean)')-(100*65853625/(65853625+62985106)+`shift') //compositional effects, 2016-18
gen logneed = .
gen logodds = log(demshare/(100-demshare))
gen prob = .
forvalues i=1/435{
	replace prob = exp(logodds-logodds[`i'])/(1+exp(logodds-logodds[`i']))
	sum prob [iw=totalvotes], meanonly
	replace logneed = r(mean) in `i'
}
replace demshare = 100-logneed*100
sum totalvotes
local totalvotes = r(sum)
local demtotalvotes = `totalvotes'*(.5+${marg}/100)
local reptotalvotes = `totalvotes'*(.5-${marg}/100)
local totalmarg = `demtotalvotes'-`reptotalvotes'
sum contested if contested == 0&margin>0
local demuncontested = r(N)
sum contested if contested == 0&margin<0
local repuncontested = r(N)

preserve
run code/uncropped.do
restore, preserve
run code/multigraph.do
restore, preserve
run code/cropped.do

#delimit ;
di `"Stats for article: if the popular vote split 50-50, dems would win $ifeven seats.
	If Dems won 75-25, they'd lose $dem75 seats.
	If Reps won 75-25, they'd lose $rep75 seats.
	Democrats needed to win the popular vote by $demmaj.
	Democrats would need to win the popular vote by $compactdemmaj if districts were compact.
	The 2018 electorate was `compositionaleffect' more conservative.
	On average, Democrats get $averageseatgap fewer seats with the same vote total.
	Democrats need a margin that's $averagevotegap larger to win the same number of seats.
	If maps were compact, on average, Democrats would get $compactaverageseatgap fewer seats with the same vote total.
	If maps were compact, on average, Democrats would need a margin that's $compactaveragevotegap larger to win the same number of seats.
	I used a polynomial of $order order to approximate vote shares based on PVI.
	Out of `totalvotes' total votes, dems won `demtotalvotes' votes and reps won `reptotalvotes' votes, giving dems a margin of `totalmarg'.
	Democrats had `demuncontested' uncontested victories, while Republicans had `repuncontested'.
	$note
	"';
