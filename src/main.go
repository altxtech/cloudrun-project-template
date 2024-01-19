package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func helloWorld(c *gin.Context){
	c.String(http.StatusOK, "Your Cloud Run app was deployed successfully.")
}

func main() {
	
	app := gin.Default()
	app.GET("/", helloWorld)


	app.Run()
}
