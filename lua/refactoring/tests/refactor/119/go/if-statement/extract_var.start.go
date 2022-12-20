package main

import (
	"fmt"
	"math"
)

type Order struct {
	quantity  float64
	itemPrice float64
}

func orderCalculation(order Order, a int, b int) (total float64) {
	temp := a * b
	test := "poggers"
	fmt.Println(temp)
	if test == "poggers" {
		fmt.Println("Sounds pretty poggers")
	}
	return order.quantity*order.itemPrice -
		math.Max(0, order.quantity-500)*order.itemPrice*0.05 +
		math.Min(order.quantity*
			order.itemPrice*0.1, 100)
}
