/* Just a little tool....

/* Copies all bytes from a bootstrap file from a given offset into an image file starting at that same offset */
/* Check booter.asm.
/* Example:
/* 			injectbl booter BYOOS_HD.dmg 0x5A
/* Will pump contents from booter into BYOOS_HD.dmg starting at 0x5A */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define IOERROR -1

#define ARG_EXEC_NAME 		0
#define ARG_BOOTSTRAP_NAME  1
#define ARG_IMAGE_NAME 		2
#define ARG_OFFSET          3
#define ARGC 				4
#define MAX_BOOTSTRAP_SIZE  448

long fileSize(FILE* pFile);
void cleanup();
long readFileToBuffer(FILE* pFile, void** ppBuffer);
long writeFileFromBuffer(FILE* pFile, void* buffer, long bufferSize);
int injectImage(int argc, char **argv);

static FILE *pBootstrap;
static FILE *pImage;

static void *pImageBuffer;
static void *pBootstrapBuffer;

int main(int argc, char *argv[])
{
	int result;
	result = injectImage(argc, argv);
	
	/* Cleanup */
	if(pImage != NULL)
		fclose(pImage);
	if(pBootstrap != NULL)
		fclose(pBootstrap);
	if(pImageBuffer != NULL)
		free(pImageBuffer);
	if(pBootstrapBuffer != NULL)
		free(pBootstrapBuffer);
	
	return result;
}

int injectImage(int argc, char **argv)
{
	//int *pOffset;
    int offset;
	
	long imgsize;
	long bootstrapsize;
    long result;

	/*******************/
	/* Check Arguments */
	/*******************/
	if (argc != ARGC)
	{
		printf("Usage: %s bootstrap.bin image.img offset\n", argv[ARG_EXEC_NAME]);
		return ARGC;
	}

    result = sscanf(argv[ARG_OFFSET],"%d",&offset);
    if (result == EOF)
    {
        result = sscanf(argv[ARG_OFFSET],"%x",&offset);
        if (result == EOF)
        {
            printf("Offset needs to be either a base 10 or a base 16 integer.");
            return ARG_OFFSET;
        }
    }
    
	/**************/	
	/* Read image */	
	/**************/
	pImage = fopen(argv[ARG_IMAGE_NAME],"rb");
	if (pImage == NULL)
	{
		printf("Error opening file %s for reading.\n", argv[ARG_IMAGE_NAME]);
		return ARG_IMAGE_NAME;
	}
	
	imgsize = readFileToBuffer(pImage,&pImageBuffer);
	if (imgsize == IOERROR)
	{
		printf("Error reading file %s.\n", argv[ARG_IMAGE_NAME]);
		return ARG_IMAGE_NAME;
	}
	
	
	/******************/	
	/* Read bootstrap */
	/******************/
	pBootstrap = fopen(argv[ARG_BOOTSTRAP_NAME],"rb");
	if (pBootstrap == NULL)
	{
		printf("Error opening file %s for reading.\n", argv[ARG_BOOTSTRAP_NAME]);
		return ARG_BOOTSTRAP_NAME;
	}
	
	bootstrapsize = readFileToBuffer(pBootstrap,&pBootstrapBuffer);
	if (bootstrapsize == IOERROR)
	{
		printf("Error reading file %s\n", argv[ARG_BOOTSTRAP_NAME]);
		return ARG_BOOTSTRAP_NAME;
	}
	else if (bootstrapsize > MAX_BOOTSTRAP_SIZE)
	{
		printf("File '%s' too long, can't be longer than %db but was %ldb.\n",argv[ARG_BOOTSTRAP_NAME], MAX_BOOTSTRAP_SIZE, bootstrapsize);
		return ARG_BOOTSTRAP_NAME;
	}
    
	
	/******************/	
	/* Copy Contents  */
	/******************/
	pImageBuffer += offset;
	memcpy(pImageBuffer, pBootstrapBuffer, (size_t) (bootstrapsize));
	
	
	/***************/	
	/* Write image */	
	/***************/
	pImage = fopen(argv[ARG_IMAGE_NAME],"wb");
	if (pImage == NULL)
	{
		printf("Error opening file %s for writing.\n", argv[ARG_IMAGE_NAME]);
		return ARG_IMAGE_NAME;
	}
	
	result = writeFileFromBuffer(pImage,pImageBuffer,imgsize);
	if (result == IOERROR)
	{
		printf("Error writing to file %s.\n", argv[ARG_IMAGE_NAME]);
		return ARG_IMAGE_NAME;
	}
	
	return 0;
}

long fileSize(FILE* pFile)
{
	long size;
	
	/* Skip to end and get size */
	fseek(pFile, 0L, SEEK_END);
	size = ftell(pFile);
	
	/* Go back to start */
	fseek(pFile, 0L, SEEK_SET);
	return size;
}


long readFileToBuffer(FILE* pFile, void** ppBuffer)
{
	
	if (pFile != NULL)
	{
		long size;
		long n = fileSize(pFile);
		*ppBuffer = malloc(n);
		
		size = fread(*ppBuffer, 1, n, pFile);
		
		if (size == n)
			return size;
	}
	
	free(*ppBuffer);
	return IOERROR;
}

long writeFileFromBuffer(FILE* pFile, void* pBuffer, long bufferSize)
{
	long size;
	
	size = fwrite(pBuffer, 1, bufferSize, pFile);
	
	if (size != bufferSize)
		return IOERROR;

	return bufferSize;
}

