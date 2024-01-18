package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func helloWorld(c *gin.Context){
	c.String(http.StatusOK, "Hello. Your Cloud Run App is running!")
}

func main() {
	
	app := gin.Default()
	app.GET("/", helloWorld)


	app.Run()
}
