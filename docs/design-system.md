# Design System

## Source of truth

The visual system comes from the Stitch designs and the Stitch-generated HTML reference.

Primary visual references:

```text
design/mobile/Dashboard.png
design/mobile/Historial.png
design/mobile/Alertas.png
design/mobile/Estado_de_la_Estacion.png
```

The exported Stitch HTML is a design reference, not the Flutter implementation.

## Fonts

### Manrope

Use for:

- headings
- titles
- body text
- labels
- interface text

### JetBrains Mono

Use for:

- measurements
- technical values
- data-oriented numeric labels

## Typography

### Label Small

- 12px
- line-height: 16px
- weight: 600

### Body Medium

- 16px
- line-height: 24px
- weight: 400

### Body Large

- 18px
- line-height: 28px
- weight: 400

### Title Medium

- 20px
- line-height: 28px
- weight: 600

### Headline Large Mobile

- 24px
- line-height: 32px
- weight: 700

### Headline Large

- 32px
- line-height: 40px
- weight: 700

### UV Display

- 72px
- line-height: 80px
- weight: 800
- letter spacing: -0.04em

### Data Label

- 14px
- line-height: 20px
- weight: 500
- letter spacing: 0.02em

## Colors

Primary:

```text
primary                    #003F87
primary-container          #0056B3
primary-fixed              #D7E2FF
primary-fixed-dim          #ACC7FF
```

Secondary:

```text
secondary                  #006E1C
secondary-container        #91F78E
secondary-fixed            #94F990
secondary-fixed-dim        #78DC77
```

Error:

```text
error                      #BA1A1A
error-container            #FFDAD6
```

Tertiary:

```text
tertiary                   #553E00
tertiary-container         #725400
tertiary-fixed             #FFDF9E
tertiary-fixed-dim         #FABD00
```

Surfaces:

```text
background                 #F8F9FA
surface                    #F8F9FA
surface-container-lowest   #FFFFFF
surface-container-low      #F3F4F5
surface-container          #EDEEEF
surface-container-high     #E7E8E9
surface-container-highest  #E1E3E4
surface-variant            #E1E3E4
surface-dim                #D9DADB
surface-bright             #F8F9FA
```

Text and outlines:

```text
on-surface                 #191C1D
on-surface-variant         #424752
outline                    #727784
outline-variant            #C2C6D4
```

## Spacing

Use the main Stitch spacing values:

```text
4px
8px
16px
20px
24px
32px
48px
```

The reference uses 20px as a primary safe margin.

## Border radius

Main values:

```text
4px
8px
12px
9999px / full pill
```

## Cards

Cards generally use:

- white surface
- rounded corners
- subtle borders where needed
- subtle shadows
- generous internal spacing

Avoid strong or heavy shadows.

## Icons

The Stitch design uses Material Symbols. Use the closest appropriate Flutter icon equivalent while preserving the visual meaning and overall appearance.

## Visual principles

The interface should feel:

- clean
- modern
- technical
- light
- readable
- data-oriented

The screenshots in `design/` have priority when judging visual similarity.

## Web

`design/web/DashBoard.png` guía la distribución de escritorio: lateral azul
oscuro `#141E32`, selección índigo `#4B4EDB`, superficie blanca, métricas en
verde `#17994D`, azul `#3764D7` y violeta `#8260B6`. La web conserva datos
reales del proyecto (UV, temperatura y humedad); CO₂ y humedad de suelo de la
imagen son solo referencias visuales. Los colores de riesgo UV siguen el modelo
compartido y siempre incluyen una etiqueta textual.
