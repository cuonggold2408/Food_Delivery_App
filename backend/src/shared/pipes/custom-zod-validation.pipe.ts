import { UnprocessableEntityException } from '@nestjs/common';
import { createZodValidationPipe } from 'nestjs-zod';
import { ZodError } from 'zod';

const CustomZodValidationPipe = createZodValidationPipe({
  createValidationException: (error: ZodError) => {
    const formattedErrors = error.errors.map((issue) => {
      return {
        ...issue,
        path: issue.path.join('.'),
      };
    });
    const errorMessage = formattedErrors.map((issue) => {
      return `${issue.path}: ${issue.message}`;
    });
    const errorMessageArr = errorMessage.map((message) => {
      const [key, value] = message.split(': ');
      return `${key}: ${value}`;
    });
    return new UnprocessableEntityException(errorMessageArr);
  },
});

export default CustomZodValidationPipe;
