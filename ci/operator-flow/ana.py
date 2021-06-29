#!/usr/bin/env python3
import dateutil.parser as dt
import json
import ROOT

with open('results.json') as f:
    data = json.load(f)

# Output: {'name': 'Bob', 'languages': ['English', 'Fench']}
# print(data)

intervals = (
    ('weeks', 604800),  # 60 * 60 * 24 * 7
    ('days', 86400),    # 60 * 60 * 24
    ('hours', 3600),    # 60 * 60
    ('minutes', 60),
    ('seconds', 1),
)


def display_time(seconds, granularity=2):
    result = []

    for name, count in intervals:
        value = seconds // count
        if value:
            seconds -= value * count
            if value == 1:
                name = name.rstrip('s')
            result.append("{} {}".format(value, name))
    return ', '.join(result[:granularity])


def export_images(name, canvas, exts=['pdf', 'png']):
    for ext in exts:
        canvas.Print(name+"."+ext)


admins = 'mvalarh', 'J0zi', 'mvalahtv', 'robszumski', 'dmesser', 'SamiSousa', 'ssimk0', 'jozzi'
interaction_id = 0

ROOT.gROOT.SetBatch()

ROOT.gStyle.SetTimeOffset(0)
nWeeks = 52  # weeks in history
resolution = nWeeks
nHours = 5*24  # max hours in pr merging time
tdFormat = "%Y-%m-%d"
dateTitle = "Date [YYYY-MM-DD]"
markerSize = 0.7

dateEnd = ROOT.TDatime()
dateBegin = ROOT.TDatime(dateEnd.Convert()-24*3600*7*nWeeks)
# nHours = 12
c = ROOT.TCanvas("c", "", 1280, 720)

timeVsPrTimeVsInteraction = ROOT.TH3F("timeVsPrTime", "Time to merge vs. PR date created",
                                      nHours, 0, nHours, resolution, dateBegin.Convert(), dateEnd.Convert(), 3, 0, 3)
timeVsPrTimeVsInteraction.SetStats(0)
timeVsPrTimeVsInteraction.GetXaxis().SetTitle("hours")
timeVsPrTimeVsInteraction.GetYaxis().SetTimeDisplay(1)
timeVsPrTimeVsInteraction.GetYaxis().SetTimeFormat(tdFormat)
timeVsPrTimeVsInteraction.GetYaxis().SetTitle(dateTitle)
timeVsPrTimeVsInteraction.GetZaxis().SetTitle("interaction")

for d in data:
    if not d['author'] in admins:
        date_time_obj = dt.parse(d['date_created'])
        if d['time_to_merge']/3600 < 2:
            print(d['number'], " [" + date_time_obj.strftime('%Y-%m-%d') + "](" + display_time(
                d['time_to_merge'])+')', d['author'] + " " + d['authorizer'] + " " + d['interaction'])

        # dateCurrent = ROOT.TDatime(2021,8,1,0,0,0);
        dateCurrent = ROOT.TDatime(date_time_obj.year, date_time_obj.month, date_time_obj.day,
                                   date_time_obj.hour, date_time_obj.minute, date_time_obj.second)
        if d['interaction'] == "comment by maintainer":
            interaction_id = 0
        elif d['interaction'] == "maintainer set authorized-changes":
            interaction_id = 1
        elif d['interaction'] == "none":
            interaction_id = 2
        else:
            interaction_id = -1

        timeVsPrTimeVsInteraction.Fill(
            float(d['time_to_merge'])/3600, dateCurrent.Convert(), interaction_id)

titles = ["Maintainer merged and helped contributor",
          "Maintainer merged without helping contributor", "Automatic merging (Self merged by author)"]
opt = "HIST TEXT0"
cNPrOverTime = ROOT.TCanvas("cNPrOverTime", "", 1280, 720)
cAvgTimePrOverTime = ROOT.TCanvas("cAvgTimePrOverTime", "", 1280, 720)
cNPrOverTime_hs = ROOT.THStack("cNPrOverTime_hs", "")
cAvgTimePrOverTime_hs = ROOT.THStack("cAvgTimePrOverTime_hs", "")


for i in [0, 1, 2]:
    print(str(i))
    ROOT.gStyle.SetPaintTextFormat("4.0f")
    nPrOverTime = timeVsPrTimeVsInteraction.ProjectionY(
        "proj_"+str(i), 0, -1, i+1, i+1)
    # nPrOverTime.GetYaxis().SetRangeUser(0, 50)
    nPrOverTime.SetStats(0)
    nPrOverTime.SetTitle(titles[i])
    # nPrOverTime.SetLineColor(i+2)
    nPrOverTime.SetFillColor(i+2)
    nPrOverTime.SetMarkerSize(markerSize)
    nPrOverTime.GetXaxis().SetTimeDisplay(1)
    nPrOverTime.GetXaxis().SetTimeFormat(tdFormat)
    nPrOverTime.GetYaxis().SetTitle("Count")
    cNPrOverTime_hs.Add(nPrOverTime)
    c.cd()
    nPrOverTime.Draw("HIST TEXT0")
    export_images(name="nPrOverTime"+str(i), canvas=c)

    ROOT.gStyle.SetPaintTextFormat("4.0f")
    timeVsPrTimeVsInteraction.GetZaxis().SetRange(i+1, i+1)
    avgTimePrOverTime = timeVsPrTimeVsInteraction.Project3D("xy")
    avgTimePrOverTime_profile = avgTimePrOverTime.ProfileX().ProjectionX()
    avgTimePrOverTime_profile.SetTitle(titles[i])
    avgTimePrOverTime_profile.SetMarkerSize(markerSize)
    avgTimePrOverTime_profile.SetStats(0)
    avgTimePrOverTime_profile.SetFillColor(i+2)
    avgTimePrOverTime_profile.GetXaxis().SetTimeDisplay(1)
    avgTimePrOverTime_profile.GetXaxis().SetTimeFormat(tdFormat)
    avgTimePrOverTime_profile.GetYaxis().SetTitle("hours")
    c.cd()
    avgTimePrOverTime_profile.Draw("HIST TEXT0")
    export_images(name="avgTimePrOverTime"+str(i), canvas=c)

    cAvgTimePrOverTime_hs.Add(avgTimePrOverTime_profile)
    # cAvgTimePrOverTime.cd()
    # avgTimePrOverTime_profile.DrawCopy(opt)
    # opt="HIST TEXT0 SAME"


cNPrOverTime.cd()
cNPrOverTime.SetGrid()
ROOT.gStyle.SetPaintTextFormat("4.0f")
base = "Number of PR merged over time"
cNPrOverTime_hs.SetTitle(base+" (sum)")
cNPrOverTime_hs.Draw("HIST TEXT0")
cNPrOverTime_hs.GetXaxis().SetTimeDisplay(1)
cNPrOverTime_hs.GetXaxis().SetTimeFormat(tdFormat)
cNPrOverTime_hs.GetYaxis().SetTitle("Count")
cNPrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("nPrOverTime_stack", cNPrOverTime)
cNPrOverTime_hs.SetTitle(base+" (beside)")
cNPrOverTime_hs.Draw("HIST TEXT0 nostackb")
cNPrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("nPrOverTime_nostackb", cNPrOverTime)
cNPrOverTime_hs.SetTitle(base+" (overlab)")
cNPrOverTime_hs.Draw("HIST TEXT0 nostack")
cNPrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("nPrOverTime_nostack", cNPrOverTime)


cAvgTimePrOverTime.cd()
cAvgTimePrOverTime.SetGrid()
ROOT.gStyle.SetPaintTextFormat("4.1f")
base = "Average PR merge time"
cAvgTimePrOverTime_hs.SetTitle(base+" (sum)")
cAvgTimePrOverTime_hs.Draw("HIST TEXT0")
cAvgTimePrOverTime_hs.GetXaxis().SetTimeDisplay(1)
cAvgTimePrOverTime_hs.GetXaxis().SetTimeFormat(tdFormat)
cAvgTimePrOverTime_hs.GetYaxis().SetTitle("hours")
cAvgTimePrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("avgTimePrOverTime_stack", cAvgTimePrOverTime)
cAvgTimePrOverTime_hs.SetTitle(base+" (beside)")
cAvgTimePrOverTime_hs.Draw("HIST TEXT0 nostackb")
cAvgTimePrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("avgTimePrOverTime_nostackb", cAvgTimePrOverTime)
cAvgTimePrOverTime_hs.SetTitle(base+" (overlap)")
cAvgTimePrOverTime_hs.Draw("HIST TEXT0 nostack")
cAvgTimePrOverTime.BuildLegend(0.1, 0.7, 0.48, 0.9)
export_images("avgTimePrOverTime_nostack", cAvgTimePrOverTime)

c.cd()
timeVsPrTimeVsInteraction.GetZaxis().SetRange(-1, -1)
timeVsPrTimeVsInteraction.Draw("LEGO2")
export_images("timeVsPrTimeVsInteraction", c)

f = ROOT.TFile("/tmp/out.root", "RECREATE")
timeVsPrTimeVsInteraction.Write()
f.Close()
