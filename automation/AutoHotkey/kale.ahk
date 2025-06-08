texts := [
    "卡键",
    "没睡好",
    "网卡了",
    "没手感",
    "空调太低了",
	"空调太高了",
	"没改键位",
	"误触了",
	"鼠标没电了",
	"没戴耳机",
	"腱鞘炎犯了",
	"延迟太高",
	"被蒙到了",
	"地震了",
	"喝水呢"
]

!F1:: {
    Send "{Enter}"
    Sleep 100
	Randindex := Random(1, texts.Length)
    Send texts[Randindex]
    Sleep 100
    Send "{Enter}"
}