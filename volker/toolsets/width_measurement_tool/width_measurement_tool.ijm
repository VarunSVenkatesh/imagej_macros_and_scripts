/**
  * MRI width measurement tool
  * 
  * Rotate the image so that the major axis of the object in the image is parallel to the horizontal axis.
  * Measure the width of a gap between cells where the gap is dark and the membranes of 
  * the cells or bright.
  *   
  * (c) 2019, INSERM
  * 
  * written by Volker Baecker at Montpellier Ressources Imagerie (www.mri.cnrs.fr)
 *
*/
var _TOLERANCE=2000;
var _DISPLAY_PLOT=true;

var helpURL = "https://github.com/MontpellierRessourcesImagerie/imagej_macros_and_scripts/wiki/MRI_Width_Measurement_Tool";

exit();

macro "width measurement tool help [f4]" {
	run('URL...', 'url='+helpURL);
}

macro "width measurement tool help (f4) Action Tool - C070D29D3dD5eD68D76D7fD84D8cD99Da2Da3Da4Da5DbbDdaDdbC040D1cD1dD1eD1fD28D2eD2fD37D42D45D55D56D57D6bD6cD6fD79D7cD88D89DcfDe9Df3Df4C1a0D73D82D8eD9bD9cD9dDa7Da8Da9DaaDadDb7DbdDcdC010D0bD0cD18D19D1aD25D26D27D32D33DdeDeaDebDf6Df7C190D2bD39D4eD50D5cDa6Dc4Dc9DceDe5De6C050D2dD38D3eD3fD43D58D66D6aD78D7dD85D86D8bD92D98Dc5Dd6De8Df2C1c0D3aD3bD3cD4bD61D70D71D72D80Dc8Dd8De1De2C180D2aD54D59D8dD90DacDb5Dd7C050D48D6dD6eD87D8aD93D94D95D96D97Da0Dc6Dd5DdcC1b0D4aD60D62D63D81D8fD9eDb1Db4Db8Dc1Dd0Dd1De3De4C020D0dD0eD0fD1bD34D35D36D40D41D46D47D7aD7bDddDf5C190D4dD4fD51D53D5aD5bD64D74D9aDabDb9Dc0Dd9Df1C060D44D5fD65D67D69D77D7eD91Da1DbcC1f0D4cD9fDaeDafDb2Db3DbeDbfDc2Dc3Dd2Dd3De0Df0C180D2cD49D52D5dD75D83Db0Db6DbaDc7DcaDcbDccDd4De7"{
	run('URL...', 'url='+helpURL);
}

macro "rotate image (f5) Action Tool - C000T4b12r" {
	rotateImage();
}

macro "rotate image [f5]" {
	rotateImage();
}

macro "measure average width (f6) Action Tool - C000T4b12w" {
	measureAverageWidth();
}

macro "measure average width [f6]" {
	measureAverageWidth();
}

function rotateImage() {	
	width = getWidth();
	height = getHeight();
	maxDimension = maxOf(width, height);
	
	run("Set Measurements...", "area standard centroid center fit shape display redirect=None decimal=9");
	setAutoThreshold("Default dark");
	run("Create Selection");
	run("Measure");
	row = nResults-1;
	angle = getResult("Angle", row);
	run("Select None");
	run("Rotate... ", "angle="+angle+" grid=1 interpolation=Bilinear enlarge");
}


function measureAverageWidth() {
	Overlay.remove;
	if (!isOpen("average_width")) {
		Table.create("average_width");
		getLocationAndSize(x, y, width, height);
		Table.setLocationAndSize(x, y, 600, 400);
	}
	title = getTitle();
	averageWidth = getAverageWidth();
	selectWindow("average_width");
	row = Table.size;
	Table.set("image", row, title);
	Table.set("avg. width", row, averageWidth);
	Table.showRowNumbers(true);
	Table.update;
}

function getAverageWidth() {
	width = getWidth();
	title = getTitle();
	imageID = getImageID();
	maximaPositions = getMaximaPositions();
	Plot.getValues(xpoints, profile);
	if (!_DISPLAY_PLOT) run("Close");
	print("Image " + title);
	print("Maxima: ");
	Array.print(maximaPositions);
	delta=xpoints[1] - xpoints[0];
	first = firstDerivative(delta, profile);
	second = firstDerivative(delta, first);
	crossings = zeroCrossings(xpoints, second);	
	crossings = valuesBetween(crossings, maximaPositions[0], maximaPositions[1]);
	print("Inflection points: ");
	Array.print(crossings);
	averageDistance = abs(crossings[1]-crossings[0]);
	x1 = width/2.0;
	x2 = width/2.0;
	y1 = crossings[0];
	y2 = crossings[1];
	selectImage(imageID);
	a = 0;
	toUnscaled(a,y1);
	toUnscaled(a,y2);
	imageWidth = width;
	toUnscaled(imageWidth);
	makeLine(x1, y1, x2, y2, imageWidth);
	Overlay.addSelection;
	run("Select None");
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	return averageDistance;
}

function getMaximaPositions() {
	imageID = getImageID();
	result = newArray(2);
	width = getWidth();
	height = getHeight();
	x1 = width/2.0;
	x2 = width/2.0;
	y1 = 0;
	y2 = height;
	lineWidth = width;
	makeLine(x1, y1, x2, y2, lineWidth);
	run("Plot Profile");
	plotID = getImageID();
	Plot.getValues(xpoints, profile);
	selectImage(imageID);
	maxima = Array.findMaxima(profile, _TOLERANCE);
	middleIndex = profile.length / 2.0;
	maximaIndicesByMiddle = Array.copy(maxima);
	for (i = 0; i < maximaIndicesByMiddle.length; i++) {
		maximaIndicesByMiddle[i] = abs(maximaIndicesByMiddle[i] - middleIndex);
	}
	rankPositions = Array.rankPositions(maximaIndicesByMiddle);
	if (maximaIndicesByMiddle.length>=2) {
		result[0] = xpoints[maxima[rankPositions[0]]];
		result[1] = xpoints[maxima[rankPositions[1]]];
	}
	selectImage(plotID);
	return result;
}

function firstDerivative(delta, discreteCurve) {
	length = discreteCurve.length;
	derivative = newArray(length);
	if (discreteCurve.length<2) return derivative;
	derivative[0] = (discreteCurve[1]-discreteCurve[0]) / delta;
	derivative[length-1] = (discreteCurve[length-1]-discreteCurve[length-2]) / delta;
	for (i = 1; i < discreteCurve.length-1; i++) {
		derivative[i] = (discreteCurve[i+1]-discreteCurve[i-1]) / (2*delta);
	}
	return derivative;
}

function zeroCrossings(xpoints, discreteCurve) {
	crossings = newArray(0);
	deltaX = xpoints[1] - xpoints[0];
	for (i = 0; i < discreteCurve.length-1; i++) {
		if (discreteCurve[i] == 0) {
			crossings = Array.concat(crossings, xpoints[i]);
			continue;
		}
		if (discreteCurve[i]*discreteCurve[i+1]<0) {
			m = (discreteCurve[i+1] - discreteCurve[i]) / deltaX;
			b = discreteCurve[i] - (m * xpoints[i]);
			xIntercept = -b/m;
			crossings = Array.concat(crossings, xIntercept);
		}
	}
	return crossings;
}

function valuesBetween(values, min, max) {
	valuesInInterval = newArray(0);
	if (min>max) {
		tmp = min;
		min = max;
		max = tmp;
	}
	for (i = 0; i < values.length; i++) {
		if (values[i]>min && values[i]<max) {
			valuesInInterval = Array.concat(valuesInInterval, values[i]);
		}
	}
	return valuesInInterval;
}