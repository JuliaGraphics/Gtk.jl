# Simple calculator application that utilises Gtk.jl
# created by Nand Vinchhi for GCI 2019

using Gtk

win = GtkWindow("Calculator")

b1 = GtkButton("1")
b2 = GtkButton("2")
b3 = GtkButton("3")
b_plus = GtkButton("+")
b4 = GtkButton("4")
b5 = GtkButton("5")
b6 = GtkButton("6")
b_minus = GtkButton("-")
b7 = GtkButton("7")
b8 = GtkButton("8")
b9 = GtkButton("9")
b_multiply = GtkButton("x")
b_clear = GtkButton("C")
b0 = GtkButton("0")
b_equalto = GtkButton("=")
b_divide = GtkButton("÷")


hbox1 = GtkButtonBox(:h)
hbox2 = GtkButtonBox(:h)
hbox3 = GtkButtonBox(:h)
hbox4 = GtkButtonBox(:h)

push!(hbox1, b1)
push!(hbox1, b2)
push!(hbox1, b3)
push!(hbox1, b_plus)
push!(hbox2, b4)
push!(hbox2, b5)
push!(hbox2, b6)
push!(hbox2, b_minus)
push!(hbox3, b7)
push!(hbox3, b8)
push!(hbox3, b9)
push!(hbox3, b_multiply)
push!(hbox4, b_clear)
push!(hbox4, b0)
push!(hbox4, b_equalto)
push!(hbox4, b_divide)

vbox = GtkBox(:v)
label = GtkLabel("")
GAccessor.text(label,"")

push!(vbox, GtkLabel(""))
push!(vbox, label)
push!(vbox, GtkLabel(""))
push!(vbox, hbox1)
push!(vbox, hbox2)
push!(vbox, hbox3)
push!(vbox, hbox4)
push!(win, vbox)

text = ""

function calculate(s)
	x = "+ " * s
	k = split(x)
	final = 0
	
	for i = 1:length(k)
		
		if k[i] == "+"
			final += parse(Float64, k[i + 1])
		elseif k[i] == "-"
			final -= parse(Float64, k[i + 1])
		elseif k[i] == "x"
			final *= parse(Float64, k[i + 1])
		elseif k[i] == "÷"
			final /= parse(Float64, k[i + 1])
		end
	end
	return string(final)
end


function button_clicked_callback(widget)
	if widget == b1
		global text = text * "1"
        GAccessor.text(label, text)
    elseif widget == b2
    	global text = text * "2"
        GAccessor.text(label, text)
    elseif widget == b3
        global text = text * "3"
        GAccessor.text(label, text)
    elseif widget == b4
    	global text = text * "4"
        GAccessor.text(label, text)
    elseif widget == b5
        global text = text * "5"
        GAccessor.text(label, text)
    elseif widget == b6
    	global text = text * "6"
        GAccessor.text(label, text)
    elseif widget == b7
        global text = text * "7"
        GAccessor.text(label, text)
    elseif widget == b8
    	global text = text * "8"
        GAccessor.text(label, text)
    elseif widget == b9
        global text = text * "9"
        GAccessor.text(label, text)
    elseif widget == b_plus
    	global text = text * " + "
        GAccessor.text(label, text)
    elseif widget == b_minus
        global text = text * " - "
        GAccessor.text(label, text)
    elseif widget == b_multiply
    	global text = text * " x "
        GAccessor.text(label, text)
    elseif widget == b_divide
        global text = text * " ÷ "
        GAccessor.text(label, text)
    elseif widget == b0
    	global text = text * "0"
        GAccessor.text(label, text)
    elseif widget == b_clear
        global text = ""
        GAccessor.text(label, text)
    elseif widget == b_equalto
    	global text = calculate(text)
        GAccessor.text(label, text)
    end
end

id1 = signal_connect(button_clicked_callback, b1, "clicked")
id2 = signal_connect(button_clicked_callback, b2, "clicked")
id3 = signal_connect(button_clicked_callback, b3, "clicked")
id4 = signal_connect(button_clicked_callback, b4, "clicked")
id5 = signal_connect(button_clicked_callback, b5, "clicked")
id6 = signal_connect(button_clicked_callback, b6, "clicked")
id7 = signal_connect(button_clicked_callback, b7, "clicked")
id8 = signal_connect(button_clicked_callback, b8, "clicked")
id9 = signal_connect(button_clicked_callback, b9, "clicked")
id10 = signal_connect(button_clicked_callback, b0, "clicked")
id11 = signal_connect(button_clicked_callback, b_plus, "clicked")
id12 = signal_connect(button_clicked_callback, b_minus, "clicked")
id13 = signal_connect(button_clicked_callback, b_multiply, "clicked")
id14 = signal_connect(button_clicked_callback, b_divide, "clicked")
id15 = signal_connect(button_clicked_callback, b_clear, "clicked")
id16 = signal_connect(button_clicked_callback, b_equalto, "clicked")



showall(win)


