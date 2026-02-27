# Product Form Test Data

This document provides test data for filling the product form in the Admin panel. Use these examples to test different product scenarios.

## Test Scenario 1: Basic Product (Simple)

### Basic Information

- **Product Name**: `Premium Cotton T-Shirt`
- **Subtitle**: `Comfortable everyday wear`
- **Description**: `Made from 100% organic cotton, this t-shirt offers ultimate comfort and style. Perfect for casual wear, featuring a modern fit and soft texture. Available in multiple colors.`
- **Price**: `599`
- **Brand**: `EcoWear`
- **SKU**: `TSH-001-ORG`
- **Stock**: `150`

### Product Images

- Upload 3-5 product images using the "File Upload" button
- Include front view, back view, and detail shots

### Categories

- `Clothing`
- `T-Shirts`
- `Men's Wear`
- `Casual`

### Tags

- `cotton`
- `organic`
- `casual`
- `comfortable`
- `eco-friendly`

### Alternative Names

- `Cotton T-Shirt`
- `T-Shirt`
- `Organic T-Shirt`
- `Casual T-Shirt`

### Product Variants

- **Enable Product Variants**: `OFF` (disabled)

### Measurement-based Pricing

- **Enable Measurement Pricing**: `OFF` (disabled)

---

## Test Scenario 2: Product with Variants (Size & Color)

### Basic Information

- **Product Name**: `Classic Denim Jeans`
- **Subtitle**: `Slim fit, premium quality`
- **Description**: `Classic slim-fit jeans crafted from premium denim. Features include stretch comfort, fade-resistant fabric, and modern styling. Perfect for both casual and semi-formal occasions.`
- **Price**: `2499` (base price - lowest variant price)
- **Brand**: `DenimCo`
- **SKU**: `JEANS-001` (leave empty if using variants only)
- **Stock**: `0` (leave 0 if using variants)

### Product Images

- Upload 4-6 images showing different angles and colors

### Categories

- `Clothing`
- `Jeans`
- `Men's Wear`
- `Bottoms`

### Tags

- `denim`
- `slim-fit`
- `premium`
- `versatile`
- `stretch`

### Alternative Names

- `Jeans`
- `Denim Jeans`
- `Slim Fit Jeans`
- `Blue Jeans`

### Product Variants

- **Enable Product Variants**: `ON` (enabled)

#### Variant 1:

- **Attribute Name**: `Size`
- **Attribute Value**: `28`
- **Variant SKU**: `JEANS-001-28-BLUE`
- **Price**: `2499`
- **Stock**: `25`

#### Variant 2:

- **Attribute Name**: `Size`
- **Attribute Value**: `30`
- **Variant SKU**: `JEANS-001-30-BLUE`
- **Price**: `2499`
- **Stock**: `30`

#### Variant 3:

- **Attribute Name**: `Size`
- **Attribute Value**: `32`
- **Variant SKU**: `JEANS-001-32-BLUE`
- **Price**: `2499`
- **Stock**: `20`

#### Variant 4:

- **Attribute Name**: `Color`
- **Attribute Value**: `Black`
- **Variant SKU**: `JEANS-001-28-BLACK`
- **Price**: `2599`
- **Stock**: `15`

#### Variant 5:

- **Attribute Name**: `Color`
- **Attribute Value**: `Black`
- **Variant SKU**: `JEANS-001-30-BLACK`
- **Price**: `2599`
- **Stock**: `18`

### Measurement-based Pricing

- **Enable Measurement Pricing**: `OFF` (disabled)

---

## Test Scenario 3: Product with Measurement-based Pricing (Weight)

### Basic Information

- **Product Name**: `Premium Basmati Rice`
- **Subtitle**: `Aromatic long-grain rice`
- **Description**: `Premium quality basmati rice with long grains and aromatic fragrance. Perfect for biryani, pulao, and other rice dishes. Sourced from the finest farms.`
- **Price**: `450` (price per kg)
- **Brand**: `FarmFresh`
- **SKU**: `RICE-001-BAS`
- **Stock**: `500` (total stock in kg)

### Product Images

- Upload 2-3 images showing the product packaging

### Categories

- `Food & Beverages`
- `Grains & Rice`
- `Pantry Staples`
- `Organic`

### Tags

- `rice`
- `basmati`
- `organic`
- `premium`
- `long-grain`

### Alternative Names

- `Basmati Rice`
- `Long Grain Rice`
- `Aromatic Rice`
- `Premium Rice`

### Product Variants

- **Enable Product Variants**: `OFF` (disabled)

### Measurement-based Pricing

- **Enable Measurement Pricing**: `ON` (enabled)
- **Measurement Type**: `weight`
- **Default Unit**: `kg (Kilogram)`
- **Price per Unit**: `450`
- **Stock per Unit**: `500`

---

## Test Scenario 4: Product with Measurement-based Pricing (Volume)

### Basic Information

- **Product Name**: `Extra Virgin Olive Oil`
- **Subtitle**: `Cold-pressed, premium quality`
- **Description**: `Premium extra virgin olive oil, cold-pressed from the finest olives. Rich in antioxidants and healthy fats. Ideal for cooking, salads, and dressings.`
- **Price**: `899` (price per liter)
- **Brand**: `Mediterranean Gold`
- **SKU**: `OIL-001-EVO`
- **Stock**: `200` (total stock in liters)

### Product Images

- Upload 2-3 images showing the product bottle

### Categories

- `Food & Beverages`
- `Cooking Oils`
- `Pantry Staples`
- `Healthy`

### Tags

- `olive-oil`
- `extra-virgin`
- `cold-pressed`
- `premium`
- `healthy`

### Alternative Names

- `Olive Oil`
- `EVOO`
- `Extra Virgin Olive Oil`
- `Cold Pressed Oil`

### Product Variants

- **Enable Product Variants**: `OFF` (disabled)

### Measurement-based Pricing

- **Enable Measurement Pricing**: `ON` (enabled)
- **Measurement Type**: `volume`
- **Default Unit**: `liter (Liter)`
- **Price per Unit**: `899`
- **Stock per Unit**: `200`

---

## Test Scenario 5: Product with Both Variants and Measurement Pricing

### Basic Information

- **Product Name**: `Organic Whole Wheat Flour`
- **Subtitle**: `Stone-ground, nutrient-rich`
- **Description**: `Organic whole wheat flour, stone-ground to preserve nutrients. Perfect for baking bread, rotis, and other traditional dishes. Rich in fiber and protein.`
- **Price**: `180` (price per kg)
- **Brand**: `Organic Harvest`
- **SKU**: `FLOUR-001-WW`
- **Stock**: `300` (total stock in kg)

### Product Images

- Upload 2-3 images showing the product packaging

### Categories

- `Food & Beverages`
- `Flours & Grains`
- `Pantry Staples`
- `Organic`
- `Baking`

### Tags

- `flour`
- `whole-wheat`
- `organic`
- `stone-ground`
- `nutrient-rich`
- `baking`

### Alternative Names

- `Whole Wheat Flour`
- `Atta`
- `Wheat Flour`
- `Organic Atta`

### Product Variants

- **Enable Product Variants**: `ON` (enabled)

#### Variant 1:

- **Attribute Name**: `Pack Size`
- **Attribute Value**: `1 kg`
- **Variant SKU**: `FLOUR-001-WW-1KG`
- **Price**: `180`
- **Stock**: `150`

#### Variant 2:

- **Attribute Name**: `Pack Size`
- **Attribute Value**: `5 kg`
- **Variant SKU**: `FLOUR-001-WW-5KG`
- **Price**: `850`
- **Stock**: `30`

### Measurement-based Pricing

- **Enable Measurement Pricing**: `ON` (enabled)
- **Measurement Type**: `weight`
- **Default Unit**: `kg (Kilogram)`
- **Price per Unit**: `180`
- **Stock per Unit**: `300`

---

## Test Scenario 6: Electronics Product

### Basic Information

- **Product Name**: `Wireless Bluetooth Headphones`
- **Subtitle**: `Noise-cancelling, 30-hour battery`
- **Description**: `Premium wireless Bluetooth headphones with active noise cancellation. Features 30-hour battery life, quick charge, and crystal-clear audio quality. Comfortable over-ear design.`
- **Price**: `4999`
- **Brand**: `AudioTech`
- **SKU**: `HEAD-001-BT`
- **Stock**: `50`

### Product Images

- Upload 5-7 images showing different angles, packaging, and features

### Categories

- `Electronics`
- `Audio`
- `Headphones`
- `Wireless`

### Tags

- `bluetooth`
- `wireless`
- `noise-cancelling`
- `premium`
- `audio`
- `battery-life`

### Alternative Names

- `BT Headphones`
- `Wireless Headphones`
- `Noise Cancelling Headphones`
- `Bluetooth Earphones`

### Product Variants

- **Enable Product Variants**: `ON` (enabled)

#### Variant 1:

- **Attribute Name**: `Color`
- **Attribute Value**: `Black`
- **Variant SKU**: `HEAD-001-BT-BLK`
- **Price**: `4999`
- **Stock**: `25`

#### Variant 2:

- **Attribute Name**: `Color`
- **Attribute Value**: `White`
- **Variant SKU**: `HEAD-001-BT-WHT`
- **Price**: `4999`
- **Stock**: `15`

#### Variant 3:

- **Attribute Name**: `Color`
- **Attribute Value**: `Blue`
- **Variant SKU**: `HEAD-001-BT-BLU`
- **Price**: `5199`
- **Stock**: `10`

### Measurement-based Pricing

- **Enable Measurement Pricing**: `OFF` (disabled)

---

## Test Scenario 7: Clothing with Multiple Attributes

### Basic Information

- **Product Name**: `Formal Dress Shirt`
- **Subtitle**: `Wrinkle-free, breathable fabric`
- **Description**: `Premium formal dress shirt made from wrinkle-free, breathable fabric. Features include button-down collar, single-needle stitching, and slim fit. Perfect for office and formal occasions.`
- **Price**: `1299` (base price)
- **Brand**: `FormalWear`
- **SKU**: `SHIRT-001-FRM`
- **Stock**: `0` (using variants)

### Product Images

- Upload 4-6 images showing different views and colors

### Categories

- `Clothing`
- `Shirts`
- `Formal Wear`
- `Men's Wear`

### Tags

- `formal`
- `dress-shirt`
- `wrinkle-free`
- `breathable`
- `office-wear`
- `slim-fit`

### Alternative Names

- `Dress Shirt`
- `Formal Shirt`
- `Office Shirt`
- `Business Shirt`

### Product Variants

- **Enable Product Variants**: `ON` (enabled)

#### Variant 1:

- **Attribute Name**: `Size`
- **Attribute Value**: `Small`
- **Variant SKU**: `SHIRT-001-FRM-S-WHT`
- **Price**: `1299`
- **Stock**: `20`

#### Variant 2:

- **Attribute Name**: `Size`
- **Attribute Value**: `Medium`
- **Variant SKU**: `SHIRT-001-FRM-M-WHT`
- **Price**: `1299`
- **Stock**: `30`

#### Variant 3:

- **Attribute Name**: `Size`
- **Attribute Value**: `Large`
- **Variant SKU**: `SHIRT-001-FRM-L-WHT`
- **Price**: `1299`
- **Stock**: `25`

#### Variant 4:

- **Attribute Name**: `Color`
- **Attribute Value**: `Blue`
- **Variant SKU**: `SHIRT-001-FRM-S-BLU`
- **Price**: `1299`
- **Stock**: `15`

#### Variant 5:

- **Attribute Name**: `Color`
- **Attribute Value**: `Blue`
- **Variant SKU**: `SHIRT-001-FRM-M-BLU`
- **Price**: `1299`
- **Stock**: `20`

#### Variant 6:

- **Attribute Name**: `Color`
- **Attribute Value**: `Blue`
- **Variant SKU**: `SHIRT-001-FRM-L-BLU`
- **Price**: `1299`
- **Stock**: `18`

### Measurement-based Pricing

- **Enable Measurement Pricing**: `OFF` (disabled)

---

## Quick Reference: Common Test Values

### Categories (Common)

- `Clothing`, `Electronics`, `Food & Beverages`, `Home & Garden`, `Sports`, `Books`, `Toys`, `Health & Beauty`, `Automotive`, `Pet Supplies`

### Tags (Common)

- `premium`, `organic`, `bestseller`, `new-arrival`, `sale`, `eco-friendly`, `made-in-india`, `warranty`, `fast-shipping`, `customer-favorite`

### Measurement Units Available

- **Weight**: `kg (Kilogram)`, `gram (Gram)`
- **Volume**: `liter (Liter)`, `ml (Milliliter)`
- **Count**: `piece (Piece)`, `dozen (Dozen)`, `pack (Pack)`, `box (Box)`, `bag (Bag)`, `bottle (Bottle)`, `can (Can)`, `roll (Roll)`
- **Length**: `meter (Meter)`, `cm (Centimeter)`, `inch (Inch)`, `foot (Foot)`, `yard (Yard)`

### Measurement Types

- `weight` - For products sold by weight (rice, flour, etc.)
- `volume` - For products sold by volume (oil, milk, etc.)
- `length` - For products sold by length (fabric, wire, etc.)
- `count` - For products sold by count (pieces, packs, etc.)

---

## Testing Checklist

When testing the product form, verify:

- [ ] Product name is required and validated
- [ ] Images can be uploaded via MediaUploadWidget
- [ ] Image preview displays correctly
- [ ] Categories can be added dynamically
- [ ] Tags can be added and field clears after adding
- [ ] Variants can be added with attribute name and value
- [ ] Variant fields clear after adding a variant
- [ ] Measurement pricing can be enabled/disabled
- [ ] Measurement unit dropdown works correctly
- [ ] Form validation works for all required fields
- [ ] Product saves to Supabase database
- [ ] Images upload to Supabase storage
- [ ] Product variants save correctly
- [ ] Product measurements save correctly
- [ ] Form can be edited for existing products
- [ ] Cancel button works correctly
- [ ] Overflow issues are fixed in measurement pricing section

---

## Notes

1. **SKU Format**: Use a consistent format like `CATEGORY-NUMBER-ATTRIBUTE` (e.g., `TSH-001-ORG`, `JEANS-001-28-BLUE`)

2. **Price**: For products with variants, set the base price to the lowest variant price. For measurement-based pricing, set price per unit.

3. **Stock**: For products with variants, set base stock to 0 and manage stock per variant. For measurement-based pricing, set total stock in the default unit.

4. **Images**: Upload at least 1 image (required). Upload multiple images for better product presentation.

5. **Categories**: Add at least one category. The default "General" category is pre-selected.

6. **Variants**: When adding variants, ensure attribute names and values are consistent (e.g., use "Size" not "size" or "SIZE").

7. **Measurement Pricing**: Choose the appropriate measurement type and unit based on how the product is sold.
