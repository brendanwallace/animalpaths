using JSON3

struct Stuff
	a::Integer
	b::String
end

s = [Stuff(1, "hi"), Stuff(2, "hello")]
js = JSON3.pretty(s)

println(js)