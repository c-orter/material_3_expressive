## 1.2.0

### Changed

* Raise `material_ui` to `^1.8.0`. It now exports its own `RoundedPolygon`
  and `CornerRounding`, which clash with the ones this package re-exports from
  `material_new_shapes`. If you import both packages, add
  `hide CornerRounding, RoundedPolygon` to the `material_ui` import.

## 1.1.7

* Raise `material_ui` to `^1.7.0`.
* **Bottom sheets, side sheets:** predictive back works with an `onDismissRequest` guard and no longer resets content state ([#31](https://github.com/paadevelopments/material_3_expressive/pull/31), [#32](https://github.com/paadevelopments/material_3_expressive/pull/32), thanks @StillMisty).
* **Chips:** long labels truncate with an ellipsis in bounded layouts ([#30](https://github.com/paadevelopments/material_3_expressive/pull/30), thanks @StillMisty).

## 1.1.6

* Raise `material_ui` to `^1.6.0`.
* **Carousel:** add `M3ECarouselScrim.gradient` with a default bottom fade.
* **Sliders:** larger tick marks that match the end stops.
* **Bottom sheets:** no bounce when content or system bars resize while closing ([#28](https://github.com/paadevelopments/material_3_expressive/pull/28), thanks @StillMisty).
