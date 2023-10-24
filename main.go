package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"log"
)

func helloWorld(c *gin.Context){
	c.String(http.StatusOK, "Hello World")
}

func main() {
	log.Println("Hello there. This is the updated version.")
	
	app := gin.Default()
	app.GET("/", helloWorld)


	app.Run()
}
