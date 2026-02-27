# Product Form Quick Reference

Quick test data for filling the product form in the Admin panel.

## Quick Test Product (Simple)

### Basic Information
- **Product Name**: `Premium Cotton T-Shirt`
- **Subtitle**: `Comfortable everyday wear`
- **Description**: `Made from 100% organic cotton, this t-shirt offers ultimate comfort and style. Perfect for casual wear, featuring a modern fit and soft texture.`
- **Price**: `599`
- **Brand**: `EcoWear`
- **SKU**: `TSH-001-ORG`
- **Stock**: `150`

### Categories
- `Clothing`
- `T-Shirts`

### Tags
- `cotton`
- `organic`
- `casual`

### Alternative Names
- `Cotton T-Shirt`
- `T-Shirt`

### Images
- Upload at least 1 image using "File Upload" button

### Variants
- **Enable**: `OFF`

### Measurement Pricing
- **Enable**: `OFF`

---

## Product with Variants

### Basic Information
- **Product Name**: `Classic Denim Jeans`
- **Subtitle**: `Slim fit, premium quality`
- **Description**: `Classic slim-fit jeans crafted from premium denim. Features include stretch comfort, fade-resistant fabric, and modern styling.`
- **Price**: `2499`
- **Brand**: `DenimCo`
- **SKU**: `JEANS-001`
- **Stock**: `0`

### Categories
- `Clothing`
- `Jeans`

### Tags
- `denim`
- `slim-fit`
- `premium`

### Variants (Enable: `ON`)
1. **Size** = `28`, SKU: `JEANS-001-28-BLUE`, Price: `2499`, Stock: `25`
2. **Size** = `30`, SKU: `JEANS-001-30-BLUE`, Price: `2499`, Stock: `30`
3. **Size** = `32`, SKU: `JEANS-001-32-BLUE`, Price: `2499`, Stock: `20`

---

## Product with Measurement Pricing

### Basic Information
- **Product Name**: `Premium Basmati Rice`
- **Subtitle**: `Aromatic long-grain rice`
- **Description**: `Premium quality basmati rice with long grains and aromatic fragrance. Perfect for biryani, pulao, and other rice dishes.`
- **Price**: `450`
- **Brand**: `FarmFresh`
- **SKU**: `RICE-001-BAS`
- **Stock**: `500`

### Categories
- `Food & Beverages`
- `Grains & Rice`

### Tags
- `rice`
- `basmati`
- `organic`

### Measurement Pricing (Enable: `ON`)
- **Type**: `weight`
- **Unit**: `kg (Kilogram)`
- **Price per Unit**: `450`
- **Stock per Unit**: `500`

---

## Common Test Values

### Categories
- Clothing, Electronics, Food & Beverages, Home & Garden, Sports, Books, Toys, Health & Beauty

### Tags
- premium, organic, bestseller, new-arrival, sale, eco-friendly, made-in-india, warranty

### Variant Attributes
- **Size**: Small, Medium, Large, XL, 28, 30, 32, 34, 36
- **Color**: Black, White, Blue, Red, Green, Yellow
- **Material**: Cotton, Denim, Leather, Synthetic
- **Pack Size**: 1 kg, 5 kg, 10 kg, 500 ml, 1 liter

### Measurement Units
- **Weight**: kg, gram
- **Volume**: liter, ml
- **Count**: piece, dozen, pack, box
- **Length**: meter, cm, inch, foot

---

## Testing Checklist

- [ ] Product name filled (required)
- [ ] At least 1 image uploaded
- [ ] At least 1 category added
- [ ] Price entered
- [ ] Form validation works
- [ ] Product saves to database
- [ ] Images upload to storage
- [ ] Variants save correctly (if enabled)
- [ ] Measurement pricing saves correctly (if enabled)

---

## Notes

1. **SKU Format**: Use format like `CATEGORY-NUMBER` (e.g., `TSH-001`, `JEANS-001`)
2. **Price**: For variants, set base price to lowest variant price
3. **Stock**: For variants, set base stock to 0 and manage per variant
4. **Images**: Upload at least 1 image (required)
5. **Categories**: At least one category required (default: "General")










