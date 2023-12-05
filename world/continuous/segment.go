package continuous

type Segment struct {
	start Vector
	end   Vector
}

func (s Segment) Vector() Vector {
	return s.end.Minus(s.start)
}
