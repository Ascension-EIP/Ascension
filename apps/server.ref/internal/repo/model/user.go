package model

import "time"

type User struct {
	ID        uint      `gorm:"primaryKey"`
	Type      string    `gorm:"size:32;not null;default:'user'"`
	Username  string    `gorm:"uniqueIndex;not null"`
	Password  string    `gorm:"not null"`
	Sessions  []Session `gorm:"foreignKey:UserID;constraint:onDelete:CASCADE"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
	UpdatedAt time.Time `gorm:"autoUpdateTime"`
}
