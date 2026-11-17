// @date 2026-11-13
// @file user_profile_test.go
// @brief Unit tests of the user profile validation rules.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"strings"
	"testing"
	"time"
)

func TestDominantHandValidate(t *testing.T) {
	for _, hand := range []DominantHand{DominantHandLeft, DominantHandRight, DominantHandAmbidextrous} {
		if err := hand.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", hand, err)
		}
	}
	for _, hand := range []DominantHand{"", "both", "Left"} {
		if err := hand.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", hand)
		}
	}
}

func TestGradingSystemValidate(t *testing.T) {
	for _, system := range []GradingSystem{GradingSystemFont, GradingSystemFrench, GradingSystemVScale, GradingSystemYDS} {
		if err := system.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", system, err)
		}
	}
	for _, system := range []GradingSystem{"", "uiaa", "V-scale"} {
		if err := system.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", system)
		}
	}
}

// profileCase is one profile value with the error prefix expected from both
// UserProfile.Validate and UserProfilePartial.Validate ("" means valid).
type profileCase struct {
	name    string
	profile UserProfile
	wantErr string
}

func profileCases() []profileCase {
	return []profileCase{
		{name: "empty profile", profile: UserProfile{}},
		{name: "full profile", profile: UserProfile{
			BirthDate:       new(time.Date(1998, 4, 2, 0, 0, 0, 0, time.UTC)),
			HeightCM:        new(uint16(178)),
			WeightKG:        new(float32(68.5)),
			ArmSpanCM:       new(uint16(182)),
			DominantHand:    new(DominantHandRight),
			ClimbingLevel:   new("7a"),
			GradingSystem:   new(GradingSystemFrench),
			YearsOfPratice:  new(uint8(6)),
			Bio:             new("Boulder addict"),
			AvatarObjectKey: new("avatars/climber.png"),
		}},
		{name: "lowest bounds", profile: UserProfile{
			BirthDate:      new(time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC)),
			HeightCM:       new(uint16(40)),
			WeightKG:       new(float32(15)),
			ArmSpanCM:      new(uint16(40)),
			ClimbingLevel:  new(""),
			YearsOfPratice: new(uint8(0)),
			Bio:            new(""),
		}},
		{name: "highest bounds", profile: UserProfile{
			HeightCM:        new(uint16(250)),
			WeightKG:        new(float32(300)),
			ArmSpanCM:       new(uint16(250)),
			ClimbingLevel:   new(strings.Repeat("a", 64)),
			YearsOfPratice:  new(uint8(120)),
			Bio:             new(strings.Repeat("a", 2000)),
			AvatarObjectKey: new(strings.Repeat("a", 1024)),
		}},
		{name: "born before 1900", profile: UserProfile{BirthDate: new(time.Date(1899, 12, 31, 0, 0, 0, 0, time.UTC))}, wantErr: "birthdate"},
		{name: "born in the future", profile: UserProfile{BirthDate: new(time.Now().Add(24 * time.Hour))}, wantErr: "birthdate"},
		{name: "too small", profile: UserProfile{HeightCM: new(uint16(39))}, wantErr: "height"},
		{name: "too tall", profile: UserProfile{HeightCM: new(uint16(251))}, wantErr: "height"},
		{name: "too light", profile: UserProfile{WeightKG: new(float32(14.9))}, wantErr: "weight"},
		{name: "too heavy", profile: UserProfile{WeightKG: new(float32(300.1))}, wantErr: "weight"},
		{name: "arm span too short", profile: UserProfile{ArmSpanCM: new(uint16(39))}, wantErr: "armspan"},
		{name: "arm span too long", profile: UserProfile{ArmSpanCM: new(uint16(251))}, wantErr: "armspan"},
		{name: "unknown dominant hand", profile: UserProfile{DominantHand: new(DominantHand("both"))}, wantErr: "dominant hand"},
		{name: "climbing level too long", profile: UserProfile{ClimbingLevel: new(strings.Repeat("a", 65))}, wantErr: "climbing level"},
		{name: "unknown grading system", profile: UserProfile{GradingSystem: new(GradingSystem("uiaa"))}, wantErr: "grading system"},
		{name: "too many years of practice", profile: UserProfile{YearsOfPratice: new(uint8(121))}, wantErr: "years of practice"},
		{name: "bio too long", profile: UserProfile{Bio: new(strings.Repeat("a", 2001))}, wantErr: "bio"},
		{name: "avatar key too long", profile: UserProfile{AvatarObjectKey: new(strings.Repeat("a", 1025))}, wantErr: "avatar object key"},
	}
}

func checkProfileErr(t *testing.T, err error, wantErr string) {
	t.Helper()

	if wantErr == "" {
		if err != nil {
			t.Fatalf("Validate() = %v, want nil", err)
		}
		return
	}
	if err == nil || !strings.HasPrefix(err.Error(), wantErr+":") {
		t.Fatalf("Validate() = %v, want an error starting with %q", err, wantErr)
	}
}

func TestUserProfileValidate(t *testing.T) {
	for _, tt := range profileCases() {
		t.Run(tt.name, func(t *testing.T) {
			checkProfileErr(t, tt.profile.Validate(), tt.wantErr)
		})
	}
}

// toPartial turns every field of the profile into an update that sets it.
func toPartial(p UserProfile) UserProfilePartial {
	partial := UserProfilePartial{UserID: p.UserID}
	if p.BirthDate != nil {
		partial.BirthDate = new(p.BirthDate)
	}
	if p.HeightCM != nil {
		partial.HeightCM = new(p.HeightCM)
	}
	if p.WeightKG != nil {
		partial.WeightKG = new(p.WeightKG)
	}
	if p.ArmSpanCM != nil {
		partial.ArmSpanCM = new(p.ArmSpanCM)
	}
	if p.DominantHand != nil {
		partial.DominantHand = new(p.DominantHand)
	}
	if p.ClimbingLevel != nil {
		partial.ClimbingLevel = new(p.ClimbingLevel)
	}
	if p.GradingSystem != nil {
		partial.GradingSystem = new(p.GradingSystem)
	}
	if p.YearsOfPratice != nil {
		partial.YearsOfPratice = new(p.YearsOfPratice)
	}
	if p.Bio != nil {
		partial.Bio = new(p.Bio)
	}
	if p.AvatarObjectKey != nil {
		partial.AvatarObjectKey = new(p.AvatarObjectKey)
	}
	return partial
}

func TestUserProfilePartialValidate(t *testing.T) {
	for _, tt := range profileCases() {
		t.Run(tt.name, func(t *testing.T) {
			checkProfileErr(t, toPartial(tt.profile).Validate(), tt.wantErr)
		})
	}

	// Clearing a field (a non-nil pointer to nil) is always valid.
	t.Run("clear every field", func(t *testing.T) {
		cleared := UserProfilePartial{
			BirthDate:       new((*time.Time)(nil)),
			HeightCM:        new((*uint16)(nil)),
			WeightKG:        new((*float32)(nil)),
			ArmSpanCM:       new((*uint16)(nil)),
			DominantHand:    new((*DominantHand)(nil)),
			ClimbingLevel:   new((*string)(nil)),
			GradingSystem:   new((*GradingSystem)(nil)),
			YearsOfPratice:  new((*uint8)(nil)),
			Bio:             new((*string)(nil)),
			AvatarObjectKey: new((*string)(nil)),
		}
		if err := cleared.Validate(); err != nil {
			t.Fatalf("Validate() = %v, want nil", err)
		}
	})
}
