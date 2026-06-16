# Telemetor UI Architecture Requirement

Do not merely design screens.

Design a complete UI framework for Flutter that serves a similar role to CSS on the web.

The goal is to create a reusable design language that allows every future Telemetor screen to be built from composable primitives rather than custom one-off widgets.

## Core Principle

The system should feel like:

Flutter + Tailwind + CSS Variables + Design Tokens + Palantir Foundry

Every visual element must derive from a centralized design system.

No hardcoded colors.

No hardcoded spacing.

No hardcoded border styles.

No ad-hoc widget styling.

---

## Create a Telemetor Design System Layer

Design a framework called:

Telemetor Design Language (TDL)

Structure:

telemetor_ui/
├── tokens/
├── themes/
├── typography/
├── spacing/
├── borders/
├── surfaces/
├── charts/
├── layouts/
├── components/
└── telemetry_widgets/

---

## Design Tokens

All styling comes from tokens.

Example:

TDLColors.background
TDLColors.surface
TDLColors.panel
TDLColors.borderPrimary
TDLColors.borderSecondary
TDLColors.accent
TDLColors.success
TDLColors.warning
TDLColors.error

No raw color values should appear in application code.

---

## Spacing System

Create a strict spacing scale:

4
8
12
16
24
32
48

Example:

TDLSpacing.xs
TDLSpacing.sm
TDLSpacing.md
TDLSpacing.lg
TDLSpacing.xl

All layouts must use these tokens.

---

## Border System

Telemetor's visual identity relies heavily on borders.

Create:

TDLBorders.panel
TDLBorders.divider
TDLBorders.selected
TDLBorders.alert

Support:

1px borders
high contrast borders
section dividers
table dividers
graph dividers

Avoid shadows as a primary separation mechanism.

Use borders instead.

---

## Typography System

Create reusable text styles.

Examples:

TDLTextStyles.pageTitle
TDLTextStyles.sectionTitle
TDLTextStyles.metricLabel
TDLTextStyles.metricValue
TDLTextStyles.tableHeader
TDLTextStyles.caption

Use Inter throughout.

---

## Layout Engine

Build reusable layout primitives.

Examples:

TelemetryGrid
CommandCenterLayout
PanelRow
PanelColumn
StatusStrip
MissionControlLayout

Every screen should be built from layouts rather than manual Rows and Columns.

---

## Telemetry Components

Create reusable domain-specific widgets:

TelemetryMetric

TelemetryChart

TelemetryChannelList

TelemetryDeviceCard

TelemetrySessionTable

TelemetryStatusBar

TelemetryMapView

TelemetryNotificationFeed

TelemetryReplayTimeline

TelemetryConnectionIndicator

These become the building blocks of the entire application.

---

## Theme Engine

Support:

Dark Mission Mode

Light Operations Mode

Future themes:

Satellite
Drone
Industrial
Research Lab

The UI should switch themes without changing component code.

Only tokens change.

---

## Charts

Create a chart styling framework.

Shared:

axes
gridlines
legends
crosshairs
tooltips
selection states

Charts should inherit styling from the design system automatically.

No chart-specific color definitions.

---

## Goal

A developer should be able to build an entire Telemetor screen using only Telemetor UI primitives, just as a web developer builds pages using CSS classes and design tokens.

The result should feel like a mature UI platform rather than a collection of Flutter widgets.

Think:

CSS for Flutter.

Tailwind for telemetry.

Palantir for telemetry operations.

Mission-control software architecture.
