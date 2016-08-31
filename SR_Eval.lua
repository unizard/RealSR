
-- =================================
-- 2016.08.31 unizard@gmail.com
-- =================================
-- 
-- *Requirement: image package, pyssim package
-- 
-- luarocks install image
-- pip install pyssim
-- =================================


require 'image' 
local pl = require('pl.import_into')()


function eval(cmd)
	os.execute(cmd)
end

function dir( strDir, strType )
  strType = strType or "*.*"
	local strFiles = {}
	for i,f in ipairs(pl.dir.getallfiles( strDir,strType )) do
		t = { f, pl.path.basename(pl.path.dirname(f)) }
		table.insert(strFiles,t[1])
	end

	table.sort(strFiles)
  return strFiles
end


-- img : [0,255] 
function getNormImage( img )
    return img:float():div(255.0)   
end


function getSharpImage( img, scale )
  local hh = img:size(1)
  local ww = img:size(2)
  local hm = math.fmod( hh, scale )
  local wm = math.fmod( ww, scale )

  local cropimg = image.crop( img, wm, hm, ww-wm, hh-hm )
  return cropimg
end


function getDUImage(img, scale)
   
   local img_ = torch.Tensor( img:size() )
   img = torch.squeeze(img):float()

   local dimg = image.scale(img,img:size(2)/scale,img:size(1)/scale, 'bicubic')
   local uimg = image.scale(dimg,img:size(2),img:size(1), 'bicubic')
   local img_ = uimg 

   --cropimg = getCropImage(img_, scale)

   return img_
end


function getCropImage(img, scale)
    local img_ = image.crop( img, scale, scale, img:size(2)-scale, img:size(1)-scale )
    return img_
end


--
function _pyssim( str1, str2 )

    eval('pyssim img1.png img2.png > ssim.txt')
    local file = io.open('ssim.txt', 'r')
    local aa = file:read()

    local value = 0
    for i = 3, #aa do
        value = value + aa:sub(i,i)*torch.pow(10, (2-i))
    end
    --print(value)
    file:close()

    return value
end


function SSIM(img1, img2, scale)

    img1 = torch.squeeze(img1):float()
    img2 = torch.squeeze(img2):float()

    if img1:dim() > 2 then  print('[PSNR] The dimension of input image > 2') return -1 end
	if img2:dim() > 2 then  print('[PSNR] The dimension of input image > 2') return -1 end
	if img1:size(1) ~= img2:size(1) then print('img1_height ~= img2_height') return -1 end
	if img1:size(2) ~= img2:size(2) then print('img1_width ~= img2_width') return -1 end

    --
    scale = scale or 1

    if img1:max() > 1 then img1 = getNormImage( img1 ) print('img1 is normalized.') end
    if img2:max() > 1 then img2 = getNormImage( img2 ) print('img2 is normalized.') end

    if scale ~= 1 then img1_ = getSharpImage( img1, scale ) end
    if scale ~= 1 then img2_ = getSharpImage( img2, scale ) end


    str1 = 'img1.png'
    str2 = 'img2.png'
    image.save(str1, img1_)
    image.save(str2, img2_)
    value = _pyssim( str1, str2 )
    
    return value
end

function PSNR(img1, img2, scale)
    
    -- error check
    img1 = torch.squeeze(img1):float()
    img2 = torch.squeeze(img2):float()

    if img1:dim() > 2 then  print('[PSNR] The dimension of input image > 2') return -1 end
	if img2:dim() > 2 then  print('[PSNR] The dimension of input image > 2') return -1 end
	if img1:size(1) ~= img2:size(1) then print('img1_height ~= img2_height') return -1 end
	if img1:size(2) ~= img2:size(2) then print('img1_width ~= img2_width') return -1 end

    --
    scale = scale or 1

    -- if input image is not normalized, 
    if img1:max() > 1 then img1 = getNormImage( img1 ) print('img1 is normalized.') end
    if img2:max() > 1 then img2 = getNormImage( img2 ) print('img2 is normalized.') end

    if scale ~= 1 then img1_ = getSharpImage( img1, scale ) end
    if scale ~= 1 then img2_ = getSharpImage( img2, scale ) end

    local rmse = torch.sqrt( (img1_-img2_):pow(2):mean() )
    local value = 20*math.log10(1.0/rmse)

    return value
end


function EvalSR( lists2, lists3, scale )

    scale = scale or 1
    psnr_ = torch.Tensor(table.getn(lists2)):fill(0.0)
    ssim_ = torch.Tensor(table.getn(lists2)):fill(0.0)
    
    for i = 1, table.getn(lists2) do
        img1 = image.load(lists2[i]):float()
        img2 = image.load(lists3[i]):float()
        psnr_[i] = PSNR(img1,img2, scale)
        ssim_[i] = SSIM(img1,img2, scale)
    end

    print( sys.COLORS.red .. 'PSNR: ' .. psnr_:mean() )
    print( sys.COLORS.red .. 'SSIM: ' .. ssim_:mean() )
end


-- main()



print('=============== Set5 =================')
scale = 4
lists2 = dir('./Set5/' , '*_ATENE_HR.png') --print(lists2)
lists3 = dir('./Set5/' , '*_ATENE_LR.png') --print(lists3)
EvalSR( lists2, lists3, scale )

print('=============== Set14 =================')
scale = 4
lists2 = dir('./Set14/' , '*_ATENE_HR.png') --print(lists2)
lists3 = dir('./Set14/' , '*_ATENE_LR.png') --print(lists3)
EvalSR( lists2, lists3, scale )




