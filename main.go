package main

import (
	localController "utilitywarehouse/onboarding-timestamp/controller"

	"github.com/DrBenton/minidic"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	container := buildContainer()

	createEndpoints(container, e)

	e.Logger.Fatal(e.Start(":8080"))
}

func buildContainer() minidic.Container {
	container := minidic.NewContainer()

	// Inject controllers
	container.Add(minidic.NewInjection("Controller.Timestamp", func(c minidic.Container) *localController.TimestampController {
		return localController.NewTimestampController()
	}))

	return container
}

func createEndpoints(container minidic.Container, echo *echo.Echo) {
	timeGroup := echo.Group("/time")
	timeGroup.GET("/now", container.Get("Controller.Timestamp").(*localController.TimestampController).GetTimestamp)
}
