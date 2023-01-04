package controller

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

type TimestampController struct{}

func NewTimestampController() *TimestampController {
	return &TimestampController{}
}

func (t *TimestampController) GetTimestamp(c echo.Context) error {

	return c.JSON(http.StatusOK, time.Now().Unix())
}
