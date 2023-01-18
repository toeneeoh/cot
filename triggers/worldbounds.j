library WorldBounds /* v2.0.0.0
************************************************************************************
*
*	struct WorldBounds extends array
*
*		Fields
*		-------------------------
*
*			readonly static integer maxX
*			readonly static integer maxY
*			readonly static integer minX
*			readonly static integer minY
*
*			readonly static integer centerX
*			readonly static integer centerY
*
*			readonly static rect world
*			readonly static region worldRegion
*
************************************************************************************/
	private module WorldBoundInit
		private static method onInit takes nothing returns nothing
			set world = GetWorldBounds()
			
			set maxX = R2I(GetRectMaxX(world))
			set maxY = R2I(GetRectMaxY(world))
			set minX = R2I(GetRectMinX(world))
			set minY = R2I(GetRectMinY(world))
			
			set centerX = R2I((maxX + minX)/2)
			set centerY = R2I((minY + maxY)/2)

			set worldRegion = CreateRegion()
			
			call RegionAddRect(worldRegion, world)
		endmethod
	endmodule
	
	struct WorldBounds extends array
		readonly static integer maxX
		readonly static integer maxY
		readonly static integer minX
		readonly static integer minY
		
		readonly static integer centerX
		readonly static integer centerY
		
		readonly static rect world

		readonly static region worldRegion

		implement WorldBoundInit
	endstruct

    function SetUnitXBounded takes unit u, real x returns nothing
        if x >= WorldBounds.maxX then
            set x = WorldBounds.maxX - 1
        elseif x <= WorldBounds.minX then
            set x = WorldBounds.minX + 1
        endif

        call SetUnitX(u, x)
    endfunction

    function SetUnitYBounded takes unit u, real y returns nothing
        if y >= WorldBounds.maxY then
            set y = WorldBounds.maxY - 1
        elseif y <= WorldBounds.minY then
            set y = WorldBounds.minY + 1
        endif

        call SetUnitY(u, y)
    endfunction
endlibrary
