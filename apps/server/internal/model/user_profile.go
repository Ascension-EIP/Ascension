// @date 2026-09-20
// @file user_profile.go
// @brief User profile model with validation.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"time"
	"uuid"
)

type DominantHand string

const (
	DominantHandLeft         DominantHand = "left"
	DominantHandRight        DominantHand = "right"
	DominantHandAmbidextrous DominantHand = "ambidextrous"
)

func (d DominantHand) Validate() error {
	switch d {
	case DominantHandLeft, DominantHandRight, DominantHandAmbidextrous:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

type GradingSystem string

const (
	GradingSystemFont   GradingSystem = "font"
	GradingSystemFrench GradingSystem = "french"
	GradingSystemVScale GradingSystem = "v_scale"
	GradingSystemYDS    GradingSystem = "yds"
)

func (g GradingSystem) Validate() error {
	switch g {
	case GradingSystemFont, GradingSystemFrench, GradingSystemVScale, GradingSystemYDS:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

type UserProfileFilter struct {
	UserID          *uuid.UUID
	BirthDate       **time.Time
	HeightCM        **uint16
	WeightKG        **float32
	ArmSpanCM       **uint16
	DominantHand    **DominantHand
	ClimbingLevel   **string
	GradingSystem   **GradingSystem
	YearsOfPratice  **uint8
	Bio             **string
	AvatarObjectKey **string
}

type UserProfilePartial struct {
	UserID          uuid.UUID
	BirthDate       **time.Time
	HeightCM        **uint16
	WeightKG        **float32
	ArmSpanCM       **uint16
	DominantHand    **DominantHand
	ClimbingLevel   **string
	GradingSystem   **GradingSystem
	YearsOfPratice  **uint8
	Bio             **string
	AvatarObjectKey **string
}

func (p UserProfilePartial) Validate() error {
	if p.BirthDate != nil {
		if v := *p.BirthDate; v != nil {
			if err := validateTimeRange(*v, time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC), time.Now()); err != nil {
				return fmt.Errorf("birthdate: %w", err)
			}
		}
	}

	if p.HeightCM != nil {
		if v := *p.HeightCM; v != nil {
			if err := validateRange(*v, 40, 250); err != nil {
				return fmt.Errorf("height: %w", err)
			}
		}
	}

	if p.WeightKG != nil {
		if v := *p.HeightCM; v != nil {
			if err := validateRange(*v, 15, 300); err != nil {
				return fmt.Errorf("weight: %w", err)
			}
		}
	}

	if p.ArmSpanCM != nil {
		if v := *p.ArmSpanCM; v != nil {
			if err := validateRange(*v, 40, 250); err != nil {
				return fmt.Errorf("armspan: %w", err)
			}
		}
	}

	if p.DominantHand != nil {
		if v := *p.DominantHand; v != nil {
			if err := (*v).Validate(); err != nil {
				return fmt.Errorf("dominant hand: %w", err)
			}
		}
	}

	if p.ClimbingLevel != nil {
		if v := *p.ClimbingLevel; v != nil {
			if err := validateStringLen(*v, 0, 64); err != nil {
				return fmt.Errorf("climbing level: %w", err)
			}
		}
	}

	if p.GradingSystem != nil {
		if v := *p.GradingSystem; v != nil {
			if err := (*v).Validate(); err != nil {
				return fmt.Errorf("grading system: %w", err)
			}
		}
	}

	if p.YearsOfPratice != nil {
		if v := *p.YearsOfPratice; v != nil {
			if err := validateRange(*v, 0, 120); err != nil {
				return fmt.Errorf("years of practice: %w", err)
			}
		}
	}

	if p.Bio != nil {
		if v := *p.Bio; v != nil {
			if err := validateStringLen(*v, 0, 2000); err != nil {
				return fmt.Errorf("bio: %w", err)
			}
		}
	}

	if p.AvatarObjectKey != nil {
		if v := *p.AvatarObjectKey; v != nil {
			if err := validateStringLen(*v, 0, 1024); err != nil {
				return fmt.Errorf("avatar object key: %w", err)
			}
		}
	}

	return nil
}

type UserProfile struct {
	UserID          uuid.UUID
	BirthDate       *time.Time
	HeightCM        *uint16
	WeightKG        *float32
	ArmSpanCM       *uint16
	DominantHand    *DominantHand
	ClimbingLevel   *string
	GradingSystem   *GradingSystem
	YearsOfPratice  *uint8
	Bio             *string
	AvatarObjectKey *string
	CreatedAt       *time.Time
	UpdatedAt       *time.Time
}

func (u UserProfile) Validate() error {
	if u.BirthDate != nil {
		if err := validateTimeRange(*u.BirthDate, time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC), time.Now()); err != nil {
			return fmt.Errorf("birthdate: %w", err)
		}
	}

	if u.HeightCM != nil {
		if err := validateRange(*u.HeightCM, 40, 250); err != nil {
			return fmt.Errorf("height: %w", err)
		}
	}

	if u.WeightKG != nil {
		if err := validateRange(*u.WeightKG, 15, 300); err != nil {
			return fmt.Errorf("weight: %w", err)
		}
	}

	if u.ArmSpanCM != nil {
		if err := validateRange(*u.ArmSpanCM, 40, 250); err != nil {
			return fmt.Errorf("armspan: %w", err)
		}
	}

	if u.DominantHand != nil {
		if err := (*u.DominantHand).Validate(); err != nil {
			return fmt.Errorf("dominant hand: %w", err)
		}
	}

	if u.ClimbingLevel != nil {
		if err := validateStringLen(*u.ClimbingLevel, 0, 64); err != nil {
			return fmt.Errorf("climbing level: %w", err)
		}
	}

	if u.GradingSystem != nil {
		if err := (*u.GradingSystem).Validate(); err != nil {
			return fmt.Errorf("grading system: %w", err)
		}
	}

	if u.YearsOfPratice != nil {
		if err := validateRange(*u.YearsOfPratice, 0, 120); err != nil {
			return fmt.Errorf("years of practice: %w", err)
		}
	}

	if u.Bio != nil {
		if err := validateStringLen(*u.Bio, 0, 2000); err != nil {
			return fmt.Errorf("bio: %w", err)
		}
	}

	if u.AvatarObjectKey != nil {
		if err := validateStringLen(*u.AvatarObjectKey, 0, 1024); err != nil {
			return fmt.Errorf("avatar object key: %w", err)
		}
	}

	return nil
}
