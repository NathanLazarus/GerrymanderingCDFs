//master.do

clear
cd ~/GerrymanderingCDFs
//set scheme uncluttered
//(see https://github.com/graykimbrough/uncluttered-stata-graphs)
ssc install _gwtmean

import delim data/HousePopularVote.csv, clear
drop if _n<4
destring v12, gen(margin) percent
replace margin = margin*100
gen voteshare=(margin+100)/2
destring v13, gen(clintonmargin) percent
replace clintonmargin = clintonmargin*100
local share2016 = 100*65853625/(65853625+62985106)-50
gen clintonshare=(clintonmargin+100)/2
gen demshare_2016= clintonshare-`share2016'
destring v6, gen(demvotes) ignore(",")
destring v7, gen(repvotes) ignore(",")
destring v8, gen(othervotes) ignore(",")

destring v15, gen(votes2016) ignore(",")
destring v16, gen(votes_vs2016) percent
gen totalvotes = demvotes+repvotes
gen weightedturnout = sqrt(totalvotes*votes2016)
bysort v1: egen state_turnout_decline = wtmean(votes_vs2016), weight(weightedturnout)
replace totalvotes = votes2016*state_turnout_decline if totalvotes == 0 //Florida
gen contested_dem = demvotes if demvotes!=0&repvotes!=0
gen contested_rep = repvotes if demvotes!=0&repvotes!=0
gen demshare_ifcontested = 100*contested_dem/(contested_dem+contested_rep)
gen contested = demshare_ifcontested!=.
sum demshare_ifcontested [iw=totalvotes]
local contested_share = r(mean)
sum demshare_2016 if contested==1 [iw=totalvotes]
local contested_share2016 = r(mean)
local shift = `contested_share'-`contested_share2016'
gen demshare = demshare_ifcontested-`shift' if contested == 1
replace demshare = demshare_2016 if contested == 0
gen simresults2018 = demshare_ifcontested if contested == 1
replace simresults2018 = demshare_2016+`shift' if contested == 0
sum demshare_ifcontested [iw=totalvotes]
sum voteshare if contested ==1 [iw=totalvotes]
sum voteshare [iw=totalvotes]
sum simresults2018 [iw=totalvotes]
di "`shift'"

global shift = `shift'
preserve
do code/uncropped.do
restore, preserve
do code/cropped.do
restore, preserve
do code/multigraph.do
