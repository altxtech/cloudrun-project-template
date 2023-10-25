package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func helloWorld(c *gin.Context){
	c.String(http.StatusOK, "Hello. This is the updated version")
}

func main() {
	
	app := gin.Default()
	app.GET("/", helloWorld)


	app.Run()
}
